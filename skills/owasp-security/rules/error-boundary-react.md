## Wrap React component trees in ErrorBoundary with fallback UI

Error Boundaries catch JavaScript errors in child component trees and display a
fallback UI instead of crashing. CWE-755.

**Incorrect (no error boundary):**

```tsx
function App() {
  return (
    <Dashboard>
      <UserProfile />
      <OrderHistory />
    </Dashboard>
  );
}
```

**Correct (granular error boundaries):**

```tsx
class ErrorBoundary extends Component<ErrorBoundaryProps, { hasError: boolean }> {
  state = { hasError: false };
  static getDerivedStateFromError() { return { hasError: true }; }
  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    logger.error({ event: 'REACT_ERROR_BOUNDARY', error: error.message });
  }
  render() {
    if (this.state.hasError) {
      return this.props.fallback || (
        <div role="alert">
          <h2>Something went wrong</h2>
          <p>Please refresh the page or contact support.</p>
        </div>
      );
    }
    return this.props.children;
  }
}

function App() {
  return (
    <ErrorBoundary>
      <Dashboard>
        <ErrorBoundary fallback={<p>Could not load profile</p>}>
          <UserProfile />
        </ErrorBoundary>
        <ErrorBoundary fallback={<p>Could not load orders</p>}>
          <OrderHistory />
        </ErrorBoundary>
      </Dashboard>
    </ErrorBoundary>
  );
}
```

**Azure/Cloud:**

Azure Application Insights React plugin integrates with error boundaries to
automatically track component errors.

**References:**
- https://owasp.org/Top10/2025/A10_2025-Mishandling_of_Exceptional_Conditions/
- https://react.dev/reference/react/Component#catching-rendering-errors-with-an-error-boundary
