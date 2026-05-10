<?php

namespace App\Http\Requests\Api\Auth;

use Illuminate\Foundation\Http\FormRequest;

class UpdateEmailRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    public function rules(): array
    {
        $emailRule = app()->environment('testing') ? 'email' : 'email:rfc,dns';

        return [
            'email' => [
                'required',
                'string',
                $emailRule,
                'max:255',
            ],
            'current_password' => ['required', 'string', 'current_password'],
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
        $this->merge([
            'email' => mb_strtolower(trim((string) $this->input('email'))),
        ]);
    }
}
