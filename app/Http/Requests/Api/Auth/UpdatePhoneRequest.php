<?php

namespace App\Http\Requests\Api\Auth;

use App\Models\User;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdatePhoneRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    public function rules(): array
    {
        $userId = $this->user()?->id;

        return [
            'phone' => [
                'required',
                'string',
                'max:25',
                'regex:/^\+?[0-9]{8,15}$/',
                Rule::unique('users', 'phone')->ignore($userId),
            ],
            'current_password' => ['required', 'string', 'current_password'],
        ];
    }

    protected function prepareForValidation(): void
    {
        $this->merge([
            'phone' => User::normalizePhone($this->input('phone')),
        ]);
    }
}
