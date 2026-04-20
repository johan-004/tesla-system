<?php

use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Laravel\Sanctum\PersonalAccessToken;

test('api login creates independent sanctum tokens for the same user', function () {
    $user = User::factory()->create();

    $mobileLogin = $this->postJson('/api/v1/auth/login', [
        'email' => $user->email,
        'password' => 'password',
        'device_name' => 'flutter-android',
    ]);

    $mobileLogin
        ->assertOk()
        ->assertJsonPath('token_type', 'Bearer');

    $desktopLogin = $this->postJson('/api/v1/auth/login', [
        'email' => $user->email,
        'password' => 'password',
        'device_name' => 'flutter-macos',
    ]);

    $desktopLogin
        ->assertOk()
        ->assertJsonPath('token_type', 'Bearer');

    expect($mobileLogin->json('token'))->not->toBe($desktopLogin->json('token'));
    expect($user->fresh()->tokens()->count())->toBe(2);

    $this->withToken($mobileLogin->json('token'))
        ->getJson('/api/v1/auth/me')
        ->assertOk()
        ->assertJsonPath('data.email', $user->email);

    $this->withToken($desktopLogin->json('token'))
        ->getJson('/api/v1/auth/me')
        ->assertOk()
        ->assertJsonPath('data.email', $user->email);
});

test('api logout invalidates only the current sanctum token', function () {
    $user = User::factory()->create();

    $mobileLogin = $this->postJson('/api/v1/auth/login', [
        'email' => $user->email,
        'password' => 'password',
        'device_name' => 'flutter-android',
    ]);

    $desktopLogin = $this->postJson('/api/v1/auth/login', [
        'email' => $user->email,
        'password' => 'password',
        'device_name' => 'flutter-macos',
    ]);

    $mobileToken = $mobileLogin->json('token');
    $desktopToken = $desktopLogin->json('token');

    $mobileTokenId = PersonalAccessToken::findToken($mobileToken)?->id;
    $desktopTokenId = PersonalAccessToken::findToken($desktopToken)?->id;

    expect($mobileTokenId)->not->toBeNull();
    expect($desktopTokenId)->not->toBeNull();

    $this->withToken($mobileToken)
        ->postJson('/api/v1/auth/logout')
        ->assertOk();

    expect(PersonalAccessToken::find($mobileTokenId))->toBeNull();
    expect(PersonalAccessToken::find($desktopTokenId))->not->toBeNull();

    app('auth')->forgetGuards();

    $this->withToken($mobileToken)
        ->getJson('/api/v1/auth/me')
        ->assertUnauthorized();

    $this->withToken($desktopToken)
        ->getJson('/api/v1/auth/me')
        ->assertOk()
        ->assertJsonPath('data.email', $user->email);
});

test('api user can update own email with current password', function () {
    $user = User::factory()->create([
        'email' => 'owner@tesla.test',
    ]);

    $login = $this->postJson('/api/v1/auth/login', [
        'email' => $user->email,
        'password' => 'password',
        'device_name' => 'flutter-android',
    ])->assertOk();

    $token = $login->json('token');

    $this->withToken($token)
        ->patchJson('/api/v1/auth/email', [
            'email' => 'owner.actualizado@tesla.test',
            'current_password' => 'password',
        ])
        ->assertOk()
        ->assertJsonPath('data.email', 'owner.actualizado@tesla.test');

    expect($user->fresh()->email)->toBe('owner.actualizado@tesla.test');
});

test('api user can update own phone with current password', function () {
    $user = User::factory()->create([
        'phone' => '+573000000001',
    ]);

    $login = $this->postJson('/api/v1/auth/login', [
        'email' => $user->email,
        'password' => 'password',
        'device_name' => 'flutter-android',
    ])->assertOk();

    $token = $login->json('token');

    $this->withToken($token)
        ->patchJson('/api/v1/auth/phone', [
            'phone' => '+57 300 111 2233',
            'current_password' => 'password',
        ])
        ->assertOk()
        ->assertJsonPath('data.phone', '+573001112233');

    expect($user->fresh()->phone)->toBe('+573001112233');
});

test('api user can update own password with current password', function () {
    $user = User::factory()->create();

    $login = $this->postJson('/api/v1/auth/login', [
        'email' => $user->email,
        'password' => 'password',
        'device_name' => 'flutter-android',
    ])->assertOk();

    $token = $login->json('token');

    $this->withToken($token)
        ->patchJson('/api/v1/auth/password', [
            'current_password' => 'password',
            'password' => 'new-password-123',
            'password_confirmation' => 'new-password-123',
        ])
        ->assertOk();

    expect(Hash::check('new-password-123', $user->fresh()->password))->toBeTrue();
});

test('api forgot password always returns generic success response', function () {
    $this->postJson('/api/v1/auth/forgot-password', [
        'email' => 'inexistente@tesla.test',
    ])->assertOk()
        ->assertJsonPath('message', 'Si el correo existe, se enviaron instrucciones de recuperación.');
});

test('api can reset password with a valid broker token', function () {
    $user = User::factory()->create([
        'email' => 'recovery@tesla.test',
    ]);

    $token = Password::broker()->createToken($user);

    $this->postJson('/api/v1/auth/reset-password', [
        'token' => $token,
        'email' => $user->email,
        'password' => 'safe-new-password-123',
        'password_confirmation' => 'safe-new-password-123',
    ])->assertOk()
        ->assertJsonPath('message', 'Contraseña restablecida correctamente.');

    expect(Hash::check('safe-new-password-123', $user->fresh()->password))->toBeTrue();
});

test('api forgot password sms returns generic success response', function () {
    $this->postJson('/api/v1/auth/forgot-password-sms', [
        'phone' => '+573009998877',
    ])->assertOk()
        ->assertJsonPath('message', 'Si el número existe, se envió un código por SMS.');
});

test('api can reset password with a valid sms code', function () {
    $user = User::factory()->create([
        'phone' => '+573001231231',
    ]);

    DB::table('password_reset_sms_codes')->insert([
        'user_id' => $user->id,
        'phone' => $user->phone,
        'code_hash' => Hash::make('123456'),
        'attempts' => 0,
        'expires_at' => now()->addMinutes(5),
        'consumed_at' => null,
        'ip_address' => '127.0.0.1',
        'created_at' => now(),
        'updated_at' => now(),
    ]);

    $this->postJson('/api/v1/auth/reset-password-sms', [
        'phone' => $user->phone,
        'code' => '123456',
        'password' => 'sms-new-password-123',
        'password_confirmation' => 'sms-new-password-123',
    ])->assertOk()
        ->assertJsonPath('message', 'Contraseña restablecida correctamente por SMS.');

    expect(Hash::check('sms-new-password-123', $user->fresh()->password))->toBeTrue();
});
