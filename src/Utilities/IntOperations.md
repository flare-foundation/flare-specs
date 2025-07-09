
## Integer Operations

### Integer Division with Remainder Distribution

Used to distribute a total quantity $T$ as evenly as possible among $N$ items.

**Given**:
- A total quantity $T$ to distribute.
- A number of items $N$.

**Algorithm**:
1. Compute the base share:
   $$
   q = \left\lfloor \frac{T}{N} \right\rfloor
   $$
2. Compute the remainder:
   $$
   R = T \mod N
   $$
3. For each item $i$ in a fixed order:
   - If $i < R$, assign:
     $$
     t_i = q + 1
     $$
   - Otherwise, assign:
     $$
     t_i = q
     $$

**Properties**:
- The first $R$ items receive $q + 1$.
- The remaining $N - R$ items receive $q$.

### Weight-based Allocation

Generally used for distributing an integer reward amount to participants based on their weight.

**Given**:
- A total quantity $Q$ to allocate.
- A set of $n$ entities, each with a non-negative weight $w_i$ for $i = 1, \ldots, n$.
- Let $W = \sum_{i=1}^n w_i$ be the total weight.

**Algorithm:**

1. Initialize $Q_{\text{avail}} = Q$, $W_{\text{avail}} = W$.
2. For each entity $i$ in a fixed order:
    - If $w_i = 0$, assign $q_i = 0$ and continue.
    - Compute allocation:
      $$
      q_i = \left\lfloor \frac{w_i \cdot Q_{\text{avail}}}{W_{\text{avail}}} \right\rfloor
      $$
    - Update:
      $$
      Q_{\text{avail}} := Q_{\text{avail}} - q_i
      $$
      $$
      W_{\text{avail}} := W_{\text{avail}} - w_i
      $$
3. Repeat until all entities are processed.

**Properties:**
- Each allocation $q_i$ is proportional to the entity's weight relative to the remaining total weight.
- The sum of all $q_i$ does not exceed $Q$.
- This method ensures that rounding errors are distributed in a deterministic order.

