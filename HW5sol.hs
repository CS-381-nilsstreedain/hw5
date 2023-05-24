module HW5sol where
import HW5types

-- Executes a program on the input stack.
semProg :: Prog -> Stack -> Maybe Stack
semProg [] s = Just s  							-- Return stack when empty
semProg (c:cs) s = semCmd c s >>= semProg cs	-- Processes curr command

-- Executes a command on the stack.
semCmd :: Cmd -> Stack -> Maybe Stack
semCmd (LDI n) s = Just (I n : s)						-- Load int on stack
semCmd (LDB b) s = Just (B b : s)						-- Load bool on stack
semCmd ADD (I x : I y : xs) = Just (I (x + y) : xs)		-- Add top 2 ints
semCmd MULT (I x : I y : xs) = Just (I (x * y) : xs)	-- Multiply top 2 ints
semCmd DUP (x : xs) = Just (x : x : xs)					-- Duplicate top element
semCmd LEQ (I x : I y : xs) = Just (B (x <= y) : xs)	-- Compare top 2 ints
semCmd DEC (I x : xs) = Just (I (x - 1) : xs)			-- Decrement top int
semCmd SWAP (x:y:xs) = Just (y : x : xs)				-- Swap top 2 elements
semCmd (POP k) xs										-- Pop k elements
  = if k == 0 then Just xs else semCmd (POP (k - 1)) (tail xs)
semCmd (IFELSE prog1 prog2) (B x : xs)					-- Run prog based on top
  = (if x then semProg prog1 else semProg prog2) xs
semCmd _ _ = Nothing									-- Invalid operation

-- Determines the rank of a command.
rankC :: Cmd -> CmdRank
rankC (LDI _) = (0,1)
rankC (LDB _) = (0,1)
rankC (ADD) = (2,1)
rankC (MULT) = (2,1)
rankC (DUP) = (1,2)
rankC (LEQ) = (2,1)
rankC (DEC) = (1,1)
rankC (SWAP) = (2,2)
rankC (POP k) = (k,0)

-- Checks if a program can run on a stack of given size.
rankP :: Prog -> Rank -> Maybe Rank
rankP [] a = Just a							-- Return curr rank if no cmds left
rankP (IFELSE a b:xs) r						-- Process IFELSE
  = min <$> rankP a (r - 1) <*> rankP b (r - 1) >>= rankP xs
rankP (x : xs) curRank						-- If not enough elements on stack
  | curRank - m < 0 = Nothing					-- Return nothing
  | otherwise = rankP xs (curRank + r - m)  	-- Continue with rest of prog
  where (m, r) = rankC x						-- Get num added/removed

-- Executes a program on the stack.
run :: Prog -> Stack -> Result
run p s										-- Run program on stack
  | Nothing <- rankP p (length s) = RankError	-- Rank check failure
  | Just stack <- semProg p s = A stack			-- Successful execution
  | otherwise = TypeError						-- Execution error
