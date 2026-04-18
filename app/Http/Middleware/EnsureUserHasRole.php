<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureUserHasRole
{
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        $user = $request->user();
        $normalizedRoles = array_map(
            static fn (string $role) => match ($role) {
                'administradora' => 'administrador',
                'vendedora' => 'vendedor',
                default => $role,
            },
            $roles
        );

        if (! $user || ! in_array($user->normalizedRole(), $normalizedRoles, true)) {
            return response()->json([
                'message' => 'No tienes permisos para realizar esta acción.',
            ], Response::HTTP_FORBIDDEN);
        }

        return $next($request);
    }
}
