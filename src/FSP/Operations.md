
## Integer Operations

### 1. Integer Division with Remainder Distribution

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

### 2. Weight-based Allocation

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

## Signing

Signing is done with the following steps:

1. The message is hashed with keccak256.
2. The hash is prepended with string
   `"\x19Ethereum Signed Message:\n32"`
   converted to bytes according to utf-8 encoding (note that `\x19` is converted to 0x19, `\n` is converted to 0x10).
3. The prepended hash is than hashed again with keccak256 (the prepending and hashing is implemented in go-ethereum function TextAndHash).
4. The last hash is signed by signingPolicyAddress using ECDSA producing a signature which is concatenation of
   - v (1 byte) - exacted to be $27$ or $28$ in decimal.
   - r (32 bytes)
   - s (32 bytes)