# Button Behavior Map

## Auth & Onboarding
| Screen | Control | Action | Expected Result |
| --- | --- | --- | --- |
| Login | **Login** | Validate form → sign in with Supabase | User is authenticated and routed to the dashboard/home. |
| Login | **Create account / Register** | Navigate to Register screen | User can create a new account. |
| Login | **Forgot password / Set password** | Navigate to Reset/Activate screen | User can request a password reset link. |
| Register | **Create account** | Validate form → Supabase Auth sign-up → upsert owner profile | Account is created and user is routed to home. |
| Register | **Back to login** | Navigate back | User returns to login screen. |
| Reset/Activate | **Send reset link** | Trigger Supabase resetPasswordForEmail | User receives email and sees confirmation message. |
| Set New Password | **Update password** | Update password via Supabase | Password updated and user routed to login. |
| Complete Profile | **Save profile** | Update owner profile | User profile saved and routed to home. |
