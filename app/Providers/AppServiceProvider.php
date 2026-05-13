<?php

namespace App\Providers;

use App\Services\Security\SecurityAlertService;
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
        $securityAlertService = app(SecurityAlertService::class);

        RateLimiter::for('auth-login', function (Request $request) use ($securityAlertService) {
            $email = mb_strtolower(trim((string) $request->input('email', '')));
            return [
                Limit::perMinute(5)
                    ->by($request->ip().'|'.$email)
                    ->response(function (Request $request, array $headers) use ($securityAlertService) {
                        $securityAlertService->onRateLimitExceeded('auth-login', $request);
                        return response()->json([
                            'message' => 'Demasiados intentos. Intenta de nuevo en unos minutos.',
                        ], 429, $headers);
                    }),
                Limit::perHour(20)->by($request->ip()),
            ];
        });

        RateLimiter::for('auth-recovery', function (Request $request) use ($securityAlertService) {
            $identifier = mb_strtolower(trim((string) (
                $request->input('email', $request->input('phone', ''))
            )));
            return [
                Limit::perMinute(3)
                    ->by($request->ip().'|'.$identifier)
                    ->response(function (Request $request, array $headers) use ($securityAlertService) {
                        $securityAlertService->onRateLimitExceeded('auth-recovery', $request);
                        return response()->json([
                            'message' => 'Demasiados intentos de recuperación. Intenta más tarde.',
                        ], 429, $headers);
                    }),
                Limit::perDay(20)->by($request->ip()),
            ];
        });

        RateLimiter::for('auth-sensitive', function (Request $request) {
            $subject = (string) ($request->user()?->id ?: $request->ip());

            return [
                Limit::perMinute(10)->by($subject),
                Limit::perDay(100)->by($subject),
            ];
        });
    }
}
