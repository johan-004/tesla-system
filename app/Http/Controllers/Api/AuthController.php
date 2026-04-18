<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\Auth\LoginApiRequest;
use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Symfony\Component\HttpFoundation\Response;

class AuthController extends Controller
{
    public function login(LoginApiRequest $request)
    {
        $user = User::query()->where('email', (string) $request->string('email'))->first();

        if (! $user || ! Hash::check((string) $request->string('password'), $user->password)) {
            return response()->json([
                'message' => 'Credenciales inválidas.',
            ], Response::HTTP_UNPROCESSABLE_ENTITY);
        }

        $deviceName = trim((string) $request->input('device_name', 'flutter-app'));
        $token = $user->createToken(
            $deviceName !== '' ? $deviceName : 'flutter-app',
            ['*'],
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
}
