---
name: frontend-patterns
description: React and Next.js patterns — component architecture, state management, data fetching, performance optimization, accessibility, and TypeScript conventions for web apps.
metadata:
  tags: react, nextjs, typescript, frontend, web, components, state
  origin: ECC (adapted for Antigravity)
---

## When to Use

- Building or reviewing React/Next.js components
- Managing client/server state
- Implementing data fetching patterns
- Optimizing performance (memoization, lazy loading)
- Writing accessible UI components

---

## Component Patterns

### Component Structure (React + TypeScript)

```typescript
interface ProductCardProps {
  product: Product
  onAddToCart: (id: string) => void
  variant?: 'compact' | 'full'
}

function ProductCard({ product, onAddToCart, variant = 'full' }: ProductCardProps) {
  const { name, price, imageUrl } = product

  return (
    <article data-testid="product-card" className={`card card--${variant}`}>
      <img src={imageUrl} alt={name} loading="lazy" />
      <h3>{name}</h3>
      <p>{formatCurrency(price)}</p>
      <button
        onClick={() => onAddToCart(product.id)}
        aria-label={`Add ${name} to cart`}
      >
        Add to cart
      </button>
    </article>
  )
}
```

### Co-location Rule
Keep related code together:
```
components/
  ProductCard/
    ProductCard.tsx          # Component
    ProductCard.test.tsx     # Tests
    ProductCard.module.css   # Styles
    index.ts                 # Re-export
```

---

## State Management

### When to Use What

| State Type | Solution |
|---|---|
| Local UI state (open/closed, form value) | `useState` |
| Derived from other state | `useMemo` / `useCallback` |
| Shared across sibling components | Lift state up |
| Global app state | `zustand` or React Context |
| Server state (API data) | TanStack Query / SWR |
| URL state (filters, search) | `useSearchParams` (Next.js) |

### Do Not Over-Use Context
```typescript
// WRONG — nesting Context for everything creates performance issues
<UserContext.Provider>
  <ThemeContext.Provider>
    <CartContext.Provider>
      <App />
    </CartContext.Provider>
  </ThemeContext.Provider>
</UserContext.Provider>

// BETTER — use zustand for shared global state
const useCartStore = create<CartState>((set) => ({
  items: [],
  addItem: (item) => set((state) => ({ items: [...state.items, item] })),
  removeItem: (id) => set((state) => ({ items: state.items.filter(i => i.id !== id) })),
}))
```

---

## Data Fetching (Next.js App Router)

### Server Components (default — prefer these)
```typescript
// app/products/page.tsx — runs on server, no client JS needed
export default async function ProductsPage() {
  const products = await fetchProducts() // Direct DB call or API call

  return (
    <main>
      <h1>Products</h1>
      <ProductList products={products} />
    </main>
  )
}
```

### Client Data Fetching (when you need live updates)
```typescript
'use client'
import { useQuery } from '@tanstack/react-query'

function LiveInventory({ productId }: { productId: string }) {
  const { data, isLoading, error } = useQuery({
    queryKey: ['inventory', productId],
    queryFn: () => fetchInventory(productId),
    refetchInterval: 30_000,         // Poll every 30s
    staleTime: 10_000,              // Consider fresh for 10s
  })

  if (isLoading) return <Skeleton />
  if (error) return <ErrorMessage error={error} />
  return <span>{data.quantity} in stock</span>
}
```

---

## Performance Patterns

### Memoization (only when needed — measure first)
```typescript
// Memoize expensive derived data
const sortedProducts = useMemo(
  () => [...products].sort((a, b) => a.price - b.price),
  [products]
)

// Memoize callbacks passed to deeply nested components
const handleAddToCart = useCallback(
  (id: string) => cartStore.addItem(id),
  [] // No deps — stable reference
)

// Memoize a component to prevent unnecessary re-renders
const ExpensiveChart = memo(({ data }: ChartProps) => {
  return <Chart data={data} />
})
```

### Code Splitting
```typescript
import { lazy, Suspense } from 'react'

// Lazy load heavy components
const RichTextEditor = lazy(() => import('./RichTextEditor'))
const MapView = lazy(() => import('./MapView'))

function Dashboard() {
  return (
    <Suspense fallback={<Skeleton />}>
      <RichTextEditor />
    </Suspense>
  )
}
```

### Image Optimization (Next.js)
```typescript
import Image from 'next/image'

// ALWAYS use next/image over <img> in Next.js
<Image
  src="/hero.jpg"
  alt="Hero banner showing our product"
  width={1200}
  height={600}
  priority                    // Above-the-fold images
  placeholder="blur"
  blurDataURL={blurDataUrl}
/>
```

---

## Custom Hooks

```typescript
// Extract logic from components into testable hooks
function useDebounce<T>(value: T, delayMs: number): T {
  const [debouncedValue, setDebouncedValue] = useState(value)

  useEffect(() => {
    const timer = setTimeout(() => setDebouncedValue(value), delayMs)
    return () => clearTimeout(timer)
  }, [value, delayMs])

  return debouncedValue
}

function useLocalStorage<T>(key: string, initialValue: T) {
  const [stored, setStored] = useState<T>(() => {
    try {
      const item = window.localStorage.getItem(key)
      return item ? JSON.parse(item) : initialValue
    } catch {
      return initialValue
    }
  })

  const setValue = (value: T) => {
    setStored(value)
    window.localStorage.setItem(key, JSON.stringify(value))
  }

  return [stored, setValue] as const
}
```

---

## Error Boundaries

```typescript
'use client'

class ErrorBoundary extends React.Component<
  { children: ReactNode; fallback: ReactNode },
  { hasError: boolean }
> {
  state = { hasError: false }

  static getDerivedStateFromError() {
    return { hasError: true }
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    logger.error('React error boundary caught:', { error, info })
  }

  render() {
    return this.state.hasError ? this.props.fallback : this.props.children
  }
}

// Usage
<ErrorBoundary fallback={<ErrorPage />}>
  <FeatureComponent />
</ErrorBoundary>
```

---

## Accessibility Checklist

- [ ] All images have meaningful `alt` text (or `alt=""` for decorative)
- [ ] Interactive elements have `aria-label` if text content is ambiguous
- [ ] Color is NOT the only way to convey information
- [ ] Focus order follows visual layout
- [ ] Forms have associated `<label>` elements
- [ ] Modals trap focus and can be dismissed with Escape
- [ ] Touch targets are ≥ 44×44px
- [ ] `lang` attribute set on `<html>`

---

## Anti-Patterns

| Anti-Pattern | Fix |
|---|---|
| `useEffect` for data fetching | Server components or TanStack Query |
| `any` in component props | Explicit typed interfaces |
| Large monolithic component (>300 lines) | Decompose into focused sub-components |
| `<img>` in Next.js | Use `<Image>` from `next/image` |
| Missing error / loading states | Always handle all three: loading, error, data |
| Premature memoization | Profile first, memoize only hot paths |
