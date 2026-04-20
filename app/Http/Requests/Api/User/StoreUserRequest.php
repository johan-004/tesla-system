<?php

namespace App\Http\Requests\Api\User;

use App\Models\User;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rules\Password;

class StoreUserRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'phone' => ['nullable', 'string', 'max:25', 'regex:/^\+?[0-9]{8,15}$/', 'unique:users,phone'],
            'password' => ['required', 'confirmed', Password::defaults()],
            'role' => ['required', 'in:administrador,vendedor'],
        ];
    }

    protected function prepareForValidation(): void
    {
        $this->merge([
            'email' => mb_strtolower(trim((string) $this->input('email'))),
            'phone' => User::normalizePhone($this->input('phone')),
        ]);
    }
}
