<?php

namespace App\Http\Requests\Api\User;

use App\Models\User;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;

class UpdateUserRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $userId = $this->route('user')->id;
        $emailRule = app()->environment('testing') ? 'email' : 'email:rfc,dns';

        return [
            'name' => ['sometimes', 'required', 'string', 'max:255'],
            'email' => ['sometimes', 'required', $emailRule, 'max:255', Rule::unique('users', 'email')->ignore($userId)],
            'phone' => ['sometimes', 'nullable', 'string', 'max:25', 'regex:/^\+?[0-9]{8,15}$/', Rule::unique('users', 'phone')->ignore($userId)],
            'password' => ['nullable', 'confirmed', Password::defaults()],
            'role' => ['sometimes', 'required', 'in:administrador,vendedor'],
        ];
    }

    public function messages(): array
    {
        return [
            'email.email' => 'correo no existe',
        ];
    }

    protected function prepareForValidation(): void
    {
        if ($this->has('email')) {
            $this->merge([
                'email' => mb_strtolower(trim((string) $this->input('email'))),
            ]);
        }

        if ($this->has('phone')) {
            $this->merge([
                'phone' => User::normalizePhone($this->input('phone')),
            ]);
        }
    }
}
