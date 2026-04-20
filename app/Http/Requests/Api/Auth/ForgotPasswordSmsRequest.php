<?php

namespace App\Http\Requests\Api\Auth;

use App\Models\User;
use Illuminate\Foundation\Http\FormRequest;

class ForgotPasswordSmsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'phone' => ['required', 'string', 'max:25', 'regex:/^\+?[0-9]{8,15}$/'],
        ];
    }

    protected function prepareForValidation(): void
    {
        $this->merge([
            'phone' => User::normalizePhone($this->input('phone')),
        ]);
    }
}
