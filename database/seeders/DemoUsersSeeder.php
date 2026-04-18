<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DemoUsersSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Create demo users only when they do not exist yet.
     */
    public function run(): void
    {
        User::firstOrCreate(
            ['email' => 'admin@tesla-system.test'],
            [
                'name' => 'Admin Tesla',
                'password' => bcrypt('password123'),
                'role' => 'administrador',
                'email_verified_at' => now(),
            ]
        );

        User::firstOrCreate(
            ['email' => 'vendedor@tesla-system.test'],
            [
                'name' => 'Vendedor Tesla',
                'password' => bcrypt('password123'),
                'role' => 'vendedor',
                'email_verified_at' => now(),
            ]
        );
    }
}
