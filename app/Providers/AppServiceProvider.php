<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Illuminate\Pagination\Paginator;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Paginator::useTailwind();

        RateLimiter::for('auth-login', function (Request $request) {
            $email = mb_strtolower(trim((string) $request->input('email', '')));
            return Limit::perMinute(5)->by($request->ip().'|'.$email);
        });

        RateLimiter::for('auth-recovery', function (Request $request) {
            $identifier = mb_strtolower(trim((string) (
                $request->input('email', $request->input('phone', ''))
            )));
            return Limit::perMinute(3)->by($request->ip().'|'.$identifier);
        });

        RateLimiter::for('auth-sensitive', function (Request $request) {
            return Limit::perMinute(10)->by((string) $request->user()?->id ?: $request->ip());
        });
    }
}
