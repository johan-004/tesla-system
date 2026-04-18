<?php

use App\Models\User;
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
