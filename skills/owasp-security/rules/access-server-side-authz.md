## Enforce all authorization server-side — never trust the client

React route guards and conditional rendering are UX conveniences, not security
controls. Every API endpoint must independently verify that the authenticated
user has permission for the requested action. CWE-602 (Client-Side Enforcement
of Server-Side Security).

**Incorrect (React route guard with unprotected API):**

```tsx
function App() {
  const { user } = useAuth();
  return (
    <Routes>
      <Route path="/admin" element={
        user.role === 'admin' ? <AdminPanel /> : <Navigate to="/" />
      } />
    </Routes>
  );
}

app.get('/api/admin/users', authenticate, async (req, res) => {
  const users = await User.findAll();
  res.json(users);
});
```

**Correct (server-side authorization middleware enforces role):**

```tsx
function authorize(...allowedRoles: string[]) {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.user || !allowedRoles.includes(req.user.role)) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    next();
  };
}

app.get('/api/admin/users', authenticate, authorize('admin'), async (req, res) => {
  const users = await User.findAll();
  res.json(users);
});
```

**Azure/Cloud:**

Use Azure AD App Roles for role-based authorization. Define roles in the app
manifest, assign users to roles in Entra ID, and validate the `roles` claim in
the JWT on every request.

**References:**
- https://owasp.org/Top10/2025/A01_2025-Broken_Access_Control/
- CWE-602: https://cwe.mitre.org/data/definitions/602.html
