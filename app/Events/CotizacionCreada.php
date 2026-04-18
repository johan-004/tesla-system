<?php

namespace App\Events;

use App\Models\Cotizacion;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class CotizacionCreada
{
    use Dispatchable;
    use SerializesModels;

    public function __construct(
        public Cotizacion $cotizacion,
        public ?int $createdByUserId,
    ) {
    }
}
