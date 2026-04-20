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
use App\Services\Sms\SmsSender;
use Illuminate\Auth\Events\PasswordReset;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Str;
use Symfony\Component\HttpFoundation\Response;

class AuthController extends Controller
{
    public function __construct(
        private readonly SmsSender $smsSender,
    ) {
    }

    public function login(LoginApiRequest $request)
    {
        $email = mb_strtolower(trim((string) $request->string('email')));
        $user = User::query()->whereRaw('LOWER(email) = ?', [$email])->first();

        if (! $user || ! Hash::check((string) $request->string('password'), $user->password)) {
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

        $user?->update([
            'email' => mb_strtolower(trim((string) $payload['email'])),
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
        Password::sendResetLink(['email' => $email]);

        return response()->json([
            'message' => 'Si el correo existe, se enviaron instrucciones de recuperación.',
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

        $status = Password::reset(
            [
                'email' => $email,
                'password' => (string) $request->input('password'),
                'password_confirmation' => (string) $request->input('password_confirmation'),
                'token' => (string) $request->input('token'),
            ],
            function (User $user) use ($request) {
                $user->forceFill([
                    'password' => Hash::make((string) $request->input('password')),
                    'remember_token' => Str::random(60),
                ])->save();

                event(new PasswordReset($user));
            }
        );

        if ($status !== Password::PASSWORD_RESET) {
            return response()->json([
                'message' => __($status),
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        User::query()
            ->whereRaw('LOWER(email) = ?', [$email])
            ->first()?->tokens()->delete();

        return response()->json([
            'message' => 'Contraseña restablecida correctamente.',
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
}
