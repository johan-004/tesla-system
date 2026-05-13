<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Hash;

class CreateInitialAdmin extends Command
{
    protected $signature = 'app:create-initial-admin';

    protected $description = 'Crea el usuario administrador inicial de forma segura e idempotente';

    public function handle(): int
    {
        $name = 'Administrador';
        $email = 'maldonadoolave2004@gmail.com';
        $password = 'jonatan2004';

        $existingAdmin = User::query()
            ->where('role', User::ROLE_ADMINISTRADOR)
            ->first();

        if ($existingAdmin) {
            $this->info("Ya existe un administrador ({$existingAdmin->email}). No se creó un nuevo usuario.");

            return self::SUCCESS;
        }

        $existingByEmail = User::query()
            ->whereRaw('LOWER(email) = ?', [mb_strtolower($email)])
            ->first();

        if ($existingByEmail) {
            $existingByEmail->fill([
                'name' => $name,
                'role' => User::ROLE_ADMINISTRADOR,
                'password' => Hash::make($password),
            ]);
            $existingByEmail->save();

            $this->info("El usuario {$email} ya existía. Fue actualizado a administrador.");
            $this->warn('Recomendación: cambia la contraseña inicial después del primer login.');

            return self::SUCCESS;
        }

        User::query()->create([
            'name' => $name,
            'email' => $email,
            'password' => Hash::make($password),
            'role' => User::ROLE_ADMINISTRADOR,
        ]);

        $this->info("Administrador inicial creado correctamente: {$email}");
        $this->warn('Recomendación: cambia la contraseña inicial después del primer login.');

        return self::SUCCESS;
    }
}

