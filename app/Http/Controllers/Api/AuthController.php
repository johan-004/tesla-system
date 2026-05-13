<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Auth\ForgotPasswordRequest;
use App\Http\Requests\Api\Auth\ForgotPasswordSmsRequest;
use App\Http\Requests\Api\Auth\LoginApiRequest;
use App\Http\Requests\Api\Auth\ResetPasswordRequest;
use App\Http\Requests\Api\Auth\ResetPasswordSmsRequest;
use App\Http\Requests\Api\Auth\UpdateEmailRequest;
use App\Http\Requests\Api\Auth\UpdatePasswordRequest;
use App\Http\Requests\Api\Auth\UpdatePhoneRequest;
use App\Http\Resources\UserResource;
use App\Models\User;
use App\Services\Security\SecurityAlertService;
use App\Services\Sms\SmsSender;
use Illuminate\Auth\Events\PasswordReset;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Symfony\Component\HttpFoundation\Response;

class AuthController extends Controller
{
    public function __construct(
        private readonly SmsSender $smsSender,
        private readonly SecurityAlertService $securityAlertService,
    ) {
    }

    public function login(LoginApiRequest $request)
    {
        $email = mb_strtolower(trim((string) $request->string('email')));
        $user = User::query()->whereRaw('LOWER(email) = ?', [$email])->first();

        if (! $user || ! Hash::check((string) $request->string('password'), $user->password)) {
            Log::channel('security')->warning('api_login_failed', [
                'email' => $email,
                'ip' => $request->ip(),
                'user_agent' => substr((string) $request->userAgent(), 0, 255),
            ]);
            $this->securityAlertService->onFailedLogin($request, $email);

            return response()->json([
                'message' => 'Credenciales inválidas.',
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        $deviceName = trim((string) $request->input('device_name', 'flutter-app'));
        $tokenAbilities = $user->permissions();
        if ($tokenAbilities === []) {
            $tokenAbilities = ['auth'];
        }

        $token = $user->createToken(
            $deviceName !== '' ? $deviceName : 'flutter-app',
            $tokenAbilities,
        )->plainTextToken;

        Log::channel('security')->info('api_login_success', [
            'user_id' => $user->id,
            'role' => $user->normalizedRole(),
            'ip' => $request->ip(),
            'device_name' => $deviceName !== '' ? $deviceName : 'flutter-app',
        ]);

        return response()->json([
            'message' => 'Login exitoso.',
            'token_type' => 'Bearer',
            'token' => $token,
            'user' => new UserResource($user),
        ]);
    }

    public function me(Request $request)
    {
        return response()->json([
            'data' => new UserResource($request->user()),
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()?->currentAccessToken()?->delete();

        return response()->json([
            'message' => 'Sesión cerrada correctamente.',
        ]);
    }

    public function updateEmail(UpdateEmailRequest $request)
    {
        $user = $request->user();
        $payload = $request->validated();
        $email = mb_strtolower(trim((string) $payload['email']));

        $emailInUse = User::query()
            ->whereRaw('LOWER(email) = ?', [$email])
            ->where('id', '!=', $user?->id)
            ->exists();

        if ($emailInUse) {
            return response()->json([
                'message' => 'correo existente ya esta en uso',
            ]);
        }

        $code = (string) random_int(100000, 999999);

        DB::table('email_change_codes')
            ->where('user_id', $user?->id)
            ->whereNull('consumed_at')
            ->delete();

        DB::table('email_change_codes')->insert([
            'user_id' => $user?->id,
            'new_email' => $email,
            'code_hash' => Hash::make($code),
            'attempts' => 0,
            'expires_at' => now()->addMinutes(10),
            'ip_address' => $request->ip(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        try {
            Mail::raw(
                "Tesla System: tu código para confirmar el cambio de correo es {$code}. Expira en 10 minutos.",
                function ($message) use ($email): void {
                    $message
                        ->to($email)
                        ->subject('Confirmación de cambio de correo - Tesla System');
                }
            );
        } catch (\Throwable $e) {
            return response()->json([
                'message' => 'No fue posible enviar el código de confirmación. Inténtalo nuevamente.',
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        return response()->json([
            'message' => 'Te enviamos un código al nuevo correo para confirmar el cambio.',
        ]);
    }

    public function confirmEmailUpdate(Request $request)
    {
        $user = $request->user();
        $payload = $request->validate([
            'email' => ['required', 'string', 'email'],
            'code' => ['required', 'digits:6'],
        ], [
            'email.required' => 'El correo es obligatorio.',
            'email.email' => 'El correo no tiene un formato válido.',
            'code.required' => 'El código es obligatorio.',
            'code.digits' => 'El código debe tener 6 dígitos.',
        ]);

        $email = mb_strtolower(trim((string) $payload['email']));

        $entry = DB::table('email_change_codes')
            ->where('user_id', $user?->id)
            ->where('new_email', $email)
            ->whereNull('consumed_at')
            ->where('expires_at', '>', now())
            ->orderByDesc('id')
            ->first();

        if (! $entry) {
            return response()->json([
                'message' => 'Código inválido o expirado.',
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        if ((int) $entry->attempts >= 5) {
            DB::table('email_change_codes')
                ->where('id', $entry->id)
                ->update([
                    'consumed_at' => now(),
                    'updated_at' => now(),
                ]);

            return response()->json([
                'message' => 'Código inválido o expirado.',
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        DB::table('email_change_codes')
            ->where('id', $entry->id)
            ->update([
                'attempts' => ((int) $entry->attempts) + 1,
                'updated_at' => now(),
            ]);

        if (! Hash::check((string) $payload['code'], (string) $entry->code_hash)) {
            return response()->json([
                'message' => 'Código inválido o expirado.',
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        $emailInUse = User::query()
            ->whereRaw('LOWER(email) = ?', [$email])
            ->where('id', '!=', $user?->id)
            ->exists();

        if ($emailInUse) {
            return response()->json([
                'message' => 'correo existente ya esta en uso',
            ]);
        }

        $user?->update([
            'email' => $email,
        ]);

        DB::table('email_change_codes')
            ->where('id', $entry->id)
            ->update([
                'consumed_at' => now(),
                'updated_at' => now(),
            ]);

        return response()->json([
            'message' => 'Correo actualizado correctamente.',
            'data' => new UserResource($user?->fresh()),
        ]);
    }

    public function updatePassword(UpdatePasswordRequest $request)
    {
        $user = $request->user();
        $payload = $request->validated();

        $user?->update([
            'password' => (string) $payload['password'],
        ]);

        return response()->json([
            'message' => 'Contraseña actualizada correctamente.',
        ]);
    }

    public function updatePhone(UpdatePhoneRequest $request)
    {
        $user = $request->user();
        $payload = $request->validated();

        $user?->update([
            'phone' => $payload['phone'],
        ]);

        return response()->json([
            'message' => 'Teléfono actualizado correctamente.',
            'data' => new UserResource($user?->fresh()),
        ]);
    }

    public function forgotPassword(ForgotPasswordRequest $request)
    {
        $email = mb_strtolower(trim((string) $request->input('email')));
        $user = User::query()->whereRaw('LOWER(email) = ?', [$email])->first();
        if (! $user) {
            return response()->json([
                'message' => 'El correo no está registrado en el sistema.',
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        $code = (string) random_int(100000, 999999);
        DB::table('password_reset_email_codes')
            ->whereRaw('LOWER(email) = ?', [$email])
            ->whereNull('consumed_at')
            ->delete();

        DB::table('password_reset_email_codes')->insert([
            'user_id' => $user->id,
            'email' => $email,
            'code_hash' => Hash::make($code),
            'attempts' => 0,
            'expires_at' => now()->addMinutes(10),
            'ip_address' => $request->ip(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        try {
            Mail::raw(
                "Tesla System: tu código de recuperación es {$code}. Expira en 10 minutos.",
                function ($message) use ($email): void {
                    $message
                        ->to($email)
                        ->subject('Código de recuperación - Tesla System');
                }
            );
        } catch (\Throwable $e) {
            return response()->json([
                'message' => 'No fue posible enviar el correo de recuperación. Inténtalo nuevamente.',
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        return response()->json([
            'message' => 'Te enviamos un código de recuperación al correo registrado.',
        ]);
    }

    public function initialAdminStatus()
    {
        return response()->json([
            'can_register' => ! $this->hasAnyAdmin(),
        ]);
    }

    public function requestInitialAdminCode(Request $request)
    {
        if ($this->hasAnyAdmin()) {
            return response()->json([
                'message' => 'Ya existe un administrador. El registro inicial está deshabilitado.',
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        $ownerEmail = mb_strtolower(trim((string) config('mail.from.address', '')));
        $configuredApprover = mb_strtolower(trim((string) env('INITIAL_ADMIN_APPROVER_EMAIL', '')));
        if ($configuredApprover !== '') {
            $ownerEmail = $configuredApprover;
        }

        if ($ownerEmail === '' || ! filter_var($ownerEmail, FILTER_VALIDATE_EMAIL)) {
            return response()->json([
                'message' => 'No hay un correo de aprobación configurado para el registro inicial.',
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        $code = (string) random_int(100000, 999999);

        DB::table('initial_admin_registration_codes')
            ->whereRaw('LOWER(recipient_email) = ?', [$ownerEmail])
            ->whereNull('consumed_at')
            ->delete();

        DB::table('initial_admin_registration_codes')->insert([
            'recipient_email' => $ownerEmail,
            'code_hash' => Hash::make($code),
            'attempts' => 0,
            'expires_at' => now()->addMinutes(10),
            'ip_address' => $request->ip(),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        try {
            Mail::raw(
                "Tesla System: código para crear el primer administrador: {$code}. Expira en 10 minutos.",
                function ($message) use ($ownerEmail): void {
                    $message
                        ->to($ownerEmail)
                        ->subject('Código de activación admin inicial - Tesla System');
                }
            );
        } catch (\Throwable $e) {
            return response()->json([
                'message' => 'No fue posible enviar el código de activación.',
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        return response()->json([
            'message' => 'Código enviado al correo de aprobación.',
        ]);
    }

    public function registerInitialAdmin(Request $request)
    {
        if ($this->hasAnyAdmin()) {
            return response()->json([
                'message' => 'Ya existe un administrador. No se puede crear otro por registro inicial.',
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        $payload = $request->validate([
            'code' => ['required', 'digits:6'],
            'name' => ['required', 'string', 'max:120'],
            'email' => ['required', 'string', 'email:rfc,dns', 'max:255', Rule::unique('users', 'email')],
            'phone' => ['required', 'string', 'max:30'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
        ], [
            'code.required' => 'El código de verificación es obligatorio.',
            'code.digits' => 'El código debe tener 6 dígitos.',
            'name.required' => 'El nombre es obligatorio.',
            'email.required' => 'El correo es obligatorio.',
            'email.email' => 'El correo no tiene un formato válido.',
            'email.unique' => 'El correo ya está registrado.',
            'phone.required' => 'El teléfono es obligatorio.',
            'password.required' => 'La contraseña es obligatoria.',
            'password.min' => 'La contraseña debe tener al menos 8 caracteres.',
            'password.confirmed' => 'La confirmación de contraseña no coincide.',
        ]);

        $ownerEmail = mb_strtolower(trim((string) config('mail.from.address', '')));
        $configuredApprover = mb_strtolower(trim((string) env('INITIAL_ADMIN_APPROVER_EMAIL', '')));
        if ($configuredApprover !== '') {
            $ownerEmail = $configuredApprover;
        }

        if ($ownerEmail === '' || ! filter_var($ownerEmail, FILTER_VALIDATE_EMAIL)) {
            return response()->json([
                'message' => 'No hay un correo de aprobación configurado para el registro inicial.',
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        $entry = DB::table('initial_admin_registration_codes')
            ->whereRaw('LOWER(recipient_email) = ?', [$ownerEmail])
            ->whereNull('consumed_at')
            ->where('expires_at', '>', now())
            ->orderByDesc('id')
            ->first();

        if (! $entry) {
            return response()->json([
                'message' => 'Código inválido o expirado.',
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        if ((int) $entry->attempts >= 5) {
            DB::table('initial_admin_registration_codes')
                ->where('id', $entry->id)
                ->update([
                    'consumed_at' => now(),
                    'updated_at' => now(),
                ]);

            return response()->json([
                'message' => 'Código inválido o expirado.',
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        DB::table('initial_admin_registration_codes')
            ->where('id', $entry->id)
            ->update([
                'attempts' => ((int) $entry->attempts) + 1,
                'updated_at' => now(),
            ]);

        if (! Hash::check((string) $payload['code'], (string) $entry->code_hash)) {
            return response()->json([
                'message' => 'Código inválido o expirado.',
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        $user = User::query()->create([
            'name' => trim((string) $payload['name']),
            'email' => mb_strtolower(trim((string) $payload['email'])),
            'phone' => trim((string) $payload['phone']),
            'password' => Hash::make((string) $payload['password']),
            'role' => User::ROLE_ADMINISTRADOR,
        ]);

        DB::table('initial_admin_registration_codes')
            ->where('id', $entry->id)
            ->update([
                'consumed_at' => now(),
                'updated_at' => now(),
            ]);

        return response()->json([
            'message' => 'Administrador creado correctamente. Ya puedes iniciar sesión.',
            'data' => new UserResource($user),
        ], Response::HTTP_CREATED);
    }

    public function verifyInitialAdminCode(Request $request)
    {
        if ($this->hasAnyAdmin()) {
            return response()->json([
                'message' => 'Ya existe un administrador. El registro inicial está deshabilitado.',
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        $payload = $request->validate([
            'code' => ['required', 'digits:6'],
        ], [
            'code.required' => 'El código de verificación es obligatorio.',
            'code.digits' => 'El código debe tener 6 dígitos.',
        ]);

        $ownerEmail = mb_strtolower(trim((string) config('mail.from.address', '')));
        $configuredApprover = mb_strtolower(trim((string) env('INITIAL_ADMIN_APPROVER_EMAIL', '')));
        if ($configuredApprover !== '') {
            $ownerEmail = $configuredApprover;
        }

        if ($ownerEmail === '' || ! filter_var($ownerEmail, FILTER_VALIDATE_EMAIL)) {
            return response()->json([
                'message' => 'No hay un correo de aprobación configurado para el registro inicial.',
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        $entry = DB::table('initial_admin_registration_codes')
            ->whereRaw('LOWER(recipient_email) = ?', [$ownerEmail])
            ->whereNull('consumed_at')
            ->where('expires_at', '>', now())
            ->orderByDesc('id')
            ->first();

        if (! $entry) {
            return response()->json([
                'message' => 'Código inválido o expirado.',
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        if ((int) $entry->attempts >= 5) {
            DB::table('initial_admin_registration_codes')
                ->where('id', $entry->id)
                ->update([
                    'consumed_at' => now(),
                    'updated_at' => now(),
                ]);

            return response()->json([
                'message' => 'Código inválido o expirado.',
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        DB::table('initial_admin_registration_codes')
            ->where('id', $entry->id)
            ->update([
                'attempts' => ((int) $entry->attempts) + 1,
                'updated_at' => now(),
            ]);

        if (! Hash::check((string) $payload['code'], (string) $entry->code_hash)) {
            return response()->json([
                'message' => 'Código inválido o expirado.',
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        return response()->json([
            'message' => 'Código validado correctamente.',
        ]);
    }

    public function recoveryEmailExists(Request $request)
    {
        $payload = $request->validate([
            'email' => ['required', 'email'],
        ], [
            'email.required' => 'El correo es obligatorio.',
            'email.email' => 'El correo no tiene un formato válido.',
        ]);

        $email = mb_strtolower(trim((string) $payload['email']));
        $exists = User::query()->whereRaw('LOWER(email) = ?', [$email])->exists();

        return response()->json([
            'exists' => $exists,
        ]);
    }

    public function forgotPasswordSms(ForgotPasswordSmsRequest $request)
    {
        $phone = User::normalizePhone((string) $request->input('phone'));
        $user = User::query()->where('phone', $phone)->first();

        if ($user) {
            $code = (string) random_int(100000, 999999);

            DB::table('password_reset_sms_codes')
                ->where('phone', $phone)
                ->whereNull('consumed_at')
                ->delete();

            DB::table('password_reset_sms_codes')->insert([
                'user_id' => $user->id,
                'phone' => $phone,
                'code_hash' => Hash::make($code),
                'attempts' => 0,
                'expires_at' => now()->addMinutes(10),
                'ip_address' => $request->ip(),
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            $this->smsSender->send(
                $phone,
                "Tesla System: tu codigo de recuperacion es {$code}. Expira en 10 minutos."
            );
        }

        return response()->json([
            'message' => 'Si el número existe, se envió un código por SMS.',
        ]);
    }

    public function resetPassword(ResetPasswordRequest $request)
    {
        $email = mb_strtolower(trim((string) $request->input('email')));
        $user = User::query()->whereRaw('LOWER(email) = ?', [$email])->first();
        if (! $user) {
            return response()->json([
                'message' => 'Código inválido o expirado.',
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        $entry = DB::table('password_reset_email_codes')
            ->whereRaw('LOWER(email) = ?', [$email])
            ->whereNull('consumed_at')
            ->where('expires_at', '>', now())
            ->orderByDesc('id')
            ->first();

        if (! $entry) {
            return response()->json([
                'message' => 'Código inválido o expirado.',
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        if ((int) $entry->attempts >= 5) {
            DB::table('password_reset_email_codes')
                ->where('id', $entry->id)
                ->update([
                    'consumed_at' => now(),
                    'updated_at' => now(),
                ]);

            return response()->json([
                'message' => 'Código inválido o expirado.',
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        DB::table('password_reset_email_codes')
            ->where('id', $entry->id)
            ->update([
                'attempts' => ((int) $entry->attempts) + 1,
                'updated_at' => now(),
            ]);

        if (! Hash::check((string) $request->input('code'), (string) $entry->code_hash)) {
            return response()->json([
                'message' => 'Código inválido o expirado.',
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        $user->forceFill([
            'password' => Hash::make((string) $request->input('password')),
            'remember_token' => Str::random(60),
        ])->save();

        event(new PasswordReset($user));
        $user->tokens()->delete();

        DB::table('password_reset_email_codes')
            ->where('id', $entry->id)
            ->update([
                'consumed_at' => now(),
                'updated_at' => now(),
            ]);

        return response()->json([
            'message' => 'Contraseña restablecida correctamente.',
        ]);
    }

    public function verifyResetCode(Request $request)
    {
        $payload = $request->validate([
            'email' => ['required', 'email'],
            'code' => ['required', 'digits:6'],
        ], [
            'email.required' => 'El correo es obligatorio.',
            'email.email' => 'El correo no tiene un formato válido.',
            'code.required' => 'El código es obligatorio.',
            'code.digits' => 'El código debe tener 6 dígitos.',
        ]);

        $email = mb_strtolower(trim((string) $payload['email']));
        $entry = DB::table('password_reset_email_codes')
            ->whereRaw('LOWER(email) = ?', [$email])
            ->whereNull('consumed_at')
            ->where('expires_at', '>', now())
            ->orderByDesc('id')
            ->first();

        if (! $entry) {
            return response()->json([
                'message' => 'Código inválido o expirado.',
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        if ((int) $entry->attempts >= 5) {
            DB::table('password_reset_email_codes')
                ->where('id', $entry->id)
                ->update([
                    'consumed_at' => now(),
                    'updated_at' => now(),
                ]);

            return response()->json([
                'message' => 'Código inválido o expirado.',
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        DB::table('password_reset_email_codes')
            ->where('id', $entry->id)
            ->update([
                'attempts' => ((int) $entry->attempts) + 1,
                'updated_at' => now(),
            ]);

        if (! Hash::check((string) $payload['code'], (string) $entry->code_hash)) {
            return response()->json([
                'message' => 'Código inválido o expirado.',
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        return response()->json([
            'message' => 'Código validado correctamente.',
        ]);
    }

    public function resetPasswordSms(ResetPasswordSmsRequest $request)
    {
        $phone = User::normalizePhone((string) $request->input('phone'));
        $user = User::query()->where('phone', $phone)->first();

        if (! $user) {
            return response()->json([
                'message' => 'Código inválido o expirado.',
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        $entry = DB::table('password_reset_sms_codes')
            ->where('phone', $phone)
            ->whereNull('consumed_at')
            ->where('expires_at', '>', now())
            ->orderByDesc('id')
            ->first();

        if (! $entry) {
            return response()->json([
                'message' => 'Código inválido o expirado.',
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        if ((int) $entry->attempts >= 5) {
            DB::table('password_reset_sms_codes')
                ->where('id', $entry->id)
                ->update([
                    'consumed_at' => now(),
                    'updated_at' => now(),
                ]);

            return response()->json([
                'message' => 'Código inválido o expirado.',
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        DB::table('password_reset_sms_codes')
            ->where('id', $entry->id)
            ->update([
                'attempts' => ((int) $entry->attempts) + 1,
                'updated_at' => now(),
            ]);

        if (! Hash::check((string) $request->input('code'), (string) $entry->code_hash)) {
            return response()->json([
                'message' => 'Código inválido o expirado.',
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        $user->forceFill([
            'password' => Hash::make((string) $request->input('password')),
            'remember_token' => Str::random(60),
        ])->save();

        $user->tokens()->delete();

        DB::table('password_reset_sms_codes')
            ->where('id', $entry->id)
            ->update([
                'consumed_at' => now(),
                'updated_at' => now(),
            ]);

        event(new PasswordReset($user));

        return response()->json([
            'message' => 'Contraseña restablecida correctamente por SMS.',
        ]);
    }

    public function verifyResetCodeSms(Request $request)
    {
        $payload = $request->validate([
            'phone' => ['required', 'string'],
            'code' => ['required', 'digits:6'],
        ], [
            'phone.required' => 'El teléfono es obligatorio.',
            'code.required' => 'El código es obligatorio.',
            'code.digits' => 'El código debe tener 6 dígitos.',
        ]);

        $phone = User::normalizePhone((string) $payload['phone']);
        $entry = DB::table('password_reset_sms_codes')
            ->where('phone', $phone)
            ->whereNull('consumed_at')
            ->where('expires_at', '>', now())
            ->orderByDesc('id')
            ->first();

        if (! $entry) {
            return response()->json([
                'message' => 'Código inválido o expirado.',
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        if ((int) $entry->attempts >= 5) {
            DB::table('password_reset_sms_codes')
                ->where('id', $entry->id)
                ->update([
                    'consumed_at' => now(),
                    'updated_at' => now(),
                ]);

            return response()->json([
                'message' => 'Código inválido o expirado.',
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        DB::table('password_reset_sms_codes')
            ->where('id', $entry->id)
            ->update([
                'attempts' => ((int) $entry->attempts) + 1,
                'updated_at' => now(),
            ]);

        if (! Hash::check((string) $payload['code'], (string) $entry->code_hash)) {
            return response()->json([
                'message' => 'Código inválido o expirado.',
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        return response()->json([
            'message' => 'Código validado correctamente.',
        ]);
    }

    private function hasAnyAdmin(): bool
    {
        return User::query()
            ->whereIn('role', [
                User::ROLE_ADMINISTRADOR,
                User::LEGACY_ROLE_ADMINISTRADORA,
            ])
            ->exists();
    }
}
