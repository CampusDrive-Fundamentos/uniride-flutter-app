# Referencia de la API de CampusDrive / Uniride

Este documento recopila la lista completa de endpoints expuestos a través del API Gateway en `http://localhost:8080` para todos los microservicios en la arquitectura de Uniride.

> [!IMPORTANT]
> - Todas las peticiones del frontend deben apuntar a `http://localhost:8080` (el API Gateway).
> - Los endpoints que requieren autenticación esperan el encabezado HTTP: `Authorization: Bearer <JWT_TOKEN>`.

---

## Tabla de Contenidos
1. [Servicio IAM (Identidad y Gestión)](#1-servicio-iam-identidad-y-gestión)
2. [Servicio de Rutas (GIS y Plantillas de Rutas)](#2-servicio-de-rutas-gis-y-plantillas-de-rutas)
3. [Servicio de Reservas (Grupos y Carpooling)](#3-servicio-de-reservas-grupos-y-carpooling)
4. [Servicio de Finanzas (Repartición Justa, Cotizaciones y Comisiones)](#4-servicio-de-finanzas-repartición-justa-cotizaciones-y-comisiones)
5. [Servicio de Viajes (Ejecución y Ciclo de Vida del Viaje)](#5-servicio-de-viajes-ejecución-y-ciclo-de-vida-del-viaje)

---

## 1. Servicio IAM (Identidad y Gestión)
**Puerto Interno:** `8081` | **Ruta Base en Gateway:** `/api/v1/auth/**`, `/api/v1/users/**`

### Registrar Estudiante
*   **Método:** `POST`
*   **Ruta:** `/api/v1/auth/signup/student`
*   **Cabeceras:** `Content-Type: application/json`
*   **Ejemplo de Cuerpo (Body):**
    ```json
    {
      "name": "Juan Perez",
      "email": "juan.perez@upc.edu.pe",
      "password": "password123",
      "phone": "987654321",
      "studentCode": "u20211a123"
    }
    ```

### Registrar Conductor
*   **Método:** `POST`
*   **Ruta:** `/api/v1/auth/signup/driver`
*   **Cabeceras:** `Content-Type: application/json`
*   **Ejemplo de Cuerpo (Body):**
    ```json
    {
      "name": "Carlos Gomez",
      "email": "carlos.gomez@gmail.com",
      "password": "password123",
      "phone": "912345678",
      "licensePlate": "ABC-123",
      "carModel": "Toyota Yaris 2022"
    }
    ```

### Iniciar Sesión (Sign In)
*   **Método:** `POST`
*   **Ruta:** `/api/v1/auth/signin`
*   **Cabeceras:** `Content-Type: application/json`
*   **Ejemplo de Cuerpo (Body):**
    ```json
    {
      "email": "juan.perez@upc.edu.pe",
      "password": "password123"
    }
    ```
*   **Respuesta:** Retorna un JSON con el token JWT (`accessToken`).

### Obtener Perfil del Usuario Actual
*   **Método:** `GET`
*   **Ruta:** `/api/v1/users/me`
*   **Cabeceras:** `Authorization: Bearer <JWT_TOKEN>`

---

## 2. Servicio de Rutas (GIS y Plantillas de Rutas)
**Puerto Interno:** `8082` | **Ruta Base en Gateway:** `/api/v1/routes/**`

### Crear Plantilla de Ruta
*   **Método:** `POST`
*   **Ruta:** `/api/v1/routes`
*   **Cabeceras:** `Authorization: Bearer <JWT_TOKEN>`, `Content-Type: application/json`
*   **Ejemplo de Cuerpo (Body):**
    ```json
    {
      "campus": "MONTERRICO",
      "destinationAddress": "Av. Primavera 2390, Santiago de Surco",
      "destinationLat": -12.104065,
      "destinationLng": -76.962902
    }
    ```

### Obtener Ruta por ID
*   **Método:** `GET`
*   **Ruta:** `/api/v1/routes/{routeId}`

### Buscar Rutas Cercanas (PostGIS)
*   **Método:** `GET`
*   **Ruta:** `/api/v1/routes/search`
*   **Parámetros de Consulta (Query Parameters):**
    *   `campus` (String, ej. `MONTERRICO`, `SAN_ISIDRO`)
    *   `lat` (Double, latitud)
    *   `lng` (Double, longitud)

### Obtener Todas las Rutas por Campus
*   **Método:** `GET`
*   **Ruta:** `/api/v1/routes/campus/{campus}`

### Añadir Parada (Waypoint / Unirse a Ruta)
*   **Método:** `PUT`
*   **Ruta:** `/api/v1/routes/{routeId}/waypoints`
*   **Cabeceras:** `Authorization: Bearer <JWT_TOKEN>`, `Content-Type: application/json`
*   **Ejemplo de Cuerpo (Body):**
    ```json
    {
      "lat": -12.115432,
      "lng": -76.978901,
      "address": "Av. Benavides 4500, Surco"
    }
    ```

### Eliminar Parada (Waypoint)
*   **Método:** `DELETE`
*   **Ruta:** `/api/v1/routes/{routeId}/waypoints`
*   **Parámetros de Consulta (Query Parameters):**
    *   `lat` (Double)
    *   `lng` (Double)

### Actualizar Visibilidad de la Ruta
*   **Método:** `PATCH`
*   **Ruta:** `/api/v1/routes/{routeId}/visibility`
*   **Parámetros de Consulta (Query Parameters):**
    *   `visibility` (String, ej. `SEARCHABLE`, `HIDDEN`)

### Eliminar Ruta
*   **Método:** `DELETE`
*   **Ruta:** `/api/v1/routes/{routeId}`

---

## 3. Servicio de Reservas (Grupos y Carpooling)
**Puerto Interno:** `8083` | **Ruta Base en Gateway:** `/api/v1/bookings/**`

### Obtener Reserva Activa del Usuario
*   **Método:** `GET`
*   **Ruta:** `/api/v1/bookings/current`
*   **Cabeceras:** `Authorization: Bearer <JWT_TOKEN>`

### Obtener Reserva por ID
*   **Método:** `GET`
*   **Ruta:** `/api/v1/bookings/{bookingId}`

### Buscar Grupos Abiertos Cercanos
*   **Método:** `GET`
*   **Ruta:** `/api/v1/bookings/search`
*   **Cabeceras:** `Authorization: Bearer <JWT_TOKEN>`
*   **Parámetros de Consulta (Query Parameters):**
    *   `campus` (String)
    *   `lat` (Double)
    *   `lng` (Double)

### Obtener Lista de Pasajeros de la Reserva
*   **Método:** `GET`
*   **Ruta:** `/api/v1/bookings/{bookingId}/passengers`

### Validar PIN del Conductor
*   **Método:** `GET`
*   **Ruta:** `/api/v1/bookings/{bookingId}/validate-pin`
*   **Parámetros de Consulta (Query Parameters):**
    *   `pin` (String)

### Crear Grupo de Reserva (Líder)
*   **Método:** `POST`
*   **Ruta:** `/api/v1/bookings`
*   **Cabeceras:** `Authorization: Bearer <JWT_TOKEN>`
*   **Parámetros de Consulta (Query Parameters):**
    *   `routeId` (Long)

### Unirse a Grupo de Reserva (Seguidor)
*   **Método:** `POST`
*   **Ruta:** `/api/v1/bookings/{bookingId}/join`
*   **Cabeceras:** `Authorization: Bearer <JWT_TOKEN>`, `Content-Type: application/json`
*   **Ejemplo de Cuerpo (Body):**
    ```json
    {
      "lat": -12.115432,
      "lng": -76.978901,
      "address": "Av. Benavides 4500, Surco"
    }
    ```

### Salir de Grupo de Reserva
*   **Método:** `DELETE`
*   **Ruta:** `/api/v1/bookings/{bookingId}/leave`
*   **Cabeceras:** `Authorization: Bearer <JWT_TOKEN>`
*   **Parámetros de Consulta (Query Parameters):**
    *   `lat` (Double)
    *   `lng` (Double)

### Cerrar/Bloquear Grupo y Generar PIN (Líder)
*   **Método:** `POST`
*   **Ruta:** `/api/v1/bookings/{bookingId}/lock`
*   **Cabeceras:** `Authorization: Bearer <JWT_TOKEN>`

### Actualizar Estado de Pago del Pasajero
*   **Método:** `PATCH`
*   **Ruta:** `/api/v1/bookings/{bookingId}/passengers/{passengerId}/payment-status`
*   **Parámetros de Consulta (Query Parameters):**
    *   `method` (String, ej. `YAPE`, `PLIN`, `CASH`)

### Cancelar Grupo de Reserva (Líder)
*   **Método:** `DELETE`
*   **Ruta:** `/api/v1/bookings/{bookingId}`
*   **Cabeceras:** `Authorization: Bearer <JWT_TOKEN>`

---

## 4. Servicio de Finanzas (Repartición Justa, Cotizaciones y Comisiones)
**Puerto Interno:** `8084` | **Ruta Base en Gateway:** `/api/v1/finance/**`

### Calcular Cotización (Fórmula de Repartición Justa)
*   **Método:** `POST`
*   **Ruta:** `/api/v1/finance/quotes`
*   **Cabeceras:** `Content-Type: application/json`
*   **Ejemplo de Cuerpo (Body):**
    ```json
    {
      "baseTaxiPrice": 30.00,
      "passengers": [
        { "passengerId": 1, "distanceKm": 5.0 },
        { "passengerId": 2, "distanceKm": 8.0 }
      ]
    }
    ```

### Procesar Liquidación
*   **Método:** `POST`
*   **Ruta:** `/api/v1/finance/settlements`
*   **Cabeceras:** `Content-Type: application/json`
*   **Ejemplo de Cuerpo (Body):**
    ```json
    {
      "tripId": 45,
      "driverId": 12,
      "totalAmount": 30.00,
      "paymentMethod": "YAPE"
    }
    ```

### Obtener Estado de la Cuenta del Conductor
*   **Método:** `GET`
*   **Ruta:** `/api/v1/finance/drivers/{driverId}/account`

### Pagar Deuda de Comisión del Conductor
*   **Método:** `POST`
*   **Ruta:** `/api/v1/finance/drivers/{driverId}/pay-debt`
*   **Cabeceras:** `Content-Type: application/json`
*   **Ejemplo de Cuerpo (Body):**
    ```json
    {
      "amount": 5.00,
      "transactionId": "TXN987654321"
    }
    ```

### Obtener Liquidaciones por Conductor
*   **Método:** `GET`
*   **Ruta:** `/api/v1/finance/drivers/{driverId}/settlements`

### Retirar Fondos (Cash Out Conductor)
*   **Método:** `POST`
*   **Ruta:** `/api/v1/finance/drivers/{driverId}/withdraw`
*   **Parámetros de Consulta (Query Parameters):**
    *   `amount` (Double)

### Obtener Detalles de una Liquidación/Recibo
*   **Método:** `GET`
*   **Ruta:** `/api/v1/finance/settlements/{id}`

### Admin: Obtener Ingresos Totales de la Plataforma
*   **Método:** `GET`
*   **Ruta:** `/api/v1/finance/admin/revenue`

### Admin: Obtener Conductores Deudores Bloqueados
*   **Método:** `GET`
*   **Ruta:** `/api/v1/finance/admin/debtors`

### Admin: Obtener Todas las Liquidaciones
*   **Método:** `GET`
*   **Ruta:** `/api/v1/finance/admin/settlements`

---

## 5. Servicio de Viajes (Ejecución y Ciclo de Vida del Viaje)
**Puerto Interno:** `8085` | **Ruta Base en Gateway:** `/api/v1/trips/**`

### Crear Viaje
*   **Método:** `POST`
*   **Ruta:** `/api/v1/trips`
*   **Cabeceras:** `Content-Type: application/json`
*   **Ejemplo de Cuerpo (Body):**
    ```json
    {
      "bookingId": 88,
      "routeId": 105,
      "campus": "MONTERRICO"
    }
    ```

### Obtener Bolsa de Viajes Disponibles (Para Conductores)
*   **Método:** `GET`
*   **Ruta:** `/api/v1/trips/available`
*   **Parámetros de Consulta (Query Parameters):**
    *   `campus` (String)

### Aceptar Viaje (Conductor)
*   **Método:** `PATCH`
*   **Ruta:** `/api/v1/trips/{tripId}/accept`
*   **Cabeceras:** `Authorization: Bearer <JWT_TOKEN>`

### Iniciar Viaje (Requiere PIN del Estudiante)
*   **Método:** `POST`
*   **Ruta:** `/api/v1/trips/{tripId}/start`
*   **Cabeceras:** `Content-Type: application/json`
*   **Ejemplo de Cuerpo (Body):**
    ```json
    {
      "securityCode": "1234"
    }
    ```

### Confirmar Llegada a Casa (Estudiante)
*   **Método:** `PATCH`
*   **Ruta:** `/api/v1/trips/{tripId}/arrivals/{passengerId}`

### Marcar Inasistencia de Pasajero (No-Show)
*   **Método:** `POST`
*   **Ruta:** `/api/v1/trips/{tripId}/passengers/{passengerId}/no-show`

### Finalizar Viaje
*   **Método:** `POST`
*   **Ruta:** `/api/v1/trips/{tripId}/complete`

### Cancelar Viaje
*   **Método:** `POST`
*   **Ruta:** `/api/v1/trips/{tripId}/cancel`
*   **Cabeceras:** `Content-Type: application/json`
*   **Ejemplo de Cuerpo (Body):**
    ```json
    {
      "reason": "Accidente en la via"
    }
    ```

### Obtener Viaje por ID
*   **Método:** `GET`
*   **Ruta:** `/api/v1/trips/{tripId}`

### Obtener Viaje Activo Actual
*   **Método:** `GET`
*   **Ruta:** `/api/v1/trips/current`
*   **Cabeceras:** `Authorization: Bearer <JWT_TOKEN>`
