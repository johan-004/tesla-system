<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'role' => $this->normalizedRole(),
            'permissions' => $this->permissions(),
            'firma_path_default' => $this->firma_path_default,
            'firma_nombre_default' => $this->firma_nombre_default,
            'firma_cargo_default' => $this->firma_cargo_default,
            'firma_empresa_default' => $this->firma_empresa_default,
            'created_at' => optional($this->created_at)->toDateTimeString(),
        ];
    }
}
