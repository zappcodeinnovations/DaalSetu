# Verified API Contracts & Endpoints

## Base URL
- Production: `https://www.daall-setu.com`
- Auth Header: `Authorization: Bearer <access_token>`

---

## 1. Authentication
- `POST /api/token/`: Obtain JWT access and refresh token.
- `POST /api/token/refresh/`: Refresh expired JWT access token.
- `POST /api/auth/login/`: User login returning user role, id, and tokens.
- `POST /api/auth/register/`: User registration.

---

## 2. User Management
- `GET /api/users/`: Retrieve paginated user list.
  - Query params: `page`, `page_size`, `role` (buyer, seller, transporter, admin, salesman), `search`.
  - Response: `{"count": int, "next": string?, "previous": string?, "results": [UserModel]}`.
- `POST /api/adduser/`: Create a new user.
  - Multipart/form-data: `mobile`, `email`, `first_name`, `last_name`, `role`, `password`, `pan_number`, `gst_number`, `gender`, `dob`, `pan_image`, `gst_image`, `tag_id`.
  - Response: `{"status": "success", "message": string, "user_id": int}`.
- `DELETE /api/users/{id}/`: Delete a user.
- `PATCH /api/users/{id}/status/`: Update user account or KYC status.

---

## 3. Brand Master & Catalog
- `GET /api/brands/`: Retrieve brands catalog.
  - Query params: `page`, `page_size`, `search`, `status` (`pending`, `active`, `inactive`, `rejected`).
  - Response: `{"count": int, "results": [AdminRecord]}`.
- `POST /api/brands/`: Create new brand.
- `PATCH /api/brands/{id}/`: Update brand details or approve (`status: 'active'`).
- `DELETE /api/brands/{id}/`: Delete brand.

---

## 4. Negotiations
- `GET /api/negotiations/{id}/`: Get negotiation history and current counter-offer.
- `POST /api/negotiations/submit/`: Submit counter-offer.
  - Payload:
    ```json
    {
      "interest_id": int,
      "price": double,
      "quantity": int,
      "packing_weight": double,
      "notes": string?
    }
    ```
  - Response: `{"status": "success", "data": {...}}`.
- `POST /api/negotiations/accept/`: Accept current terms.
- `POST /api/negotiations/reject/`: Reject counter-offer.
