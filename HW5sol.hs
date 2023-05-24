module HW5sol where

import HW5types

execute :: Prog -> Stack -> Result
execute [] s = A s
execute ((LDI x):xs) s = execute xs ((I x):s)
execute ((LDB x):xs) s = execute xs ((B x):s)
execute (DUP:xs) (z:zs) = execute xs (z:z:zs)
execute (DUP:_) [] = TypeError
execute (ADD:xs) ((I x):(I y):zs) = execute xs ((I (x+y)):zs)
execute (ADD:_) _ = TypeError
execute (MULT:xs) ((I x):(I y):zs) = execute xs ((I (x*y)):zs)
execute (MULT:_) _ = TypeError
execute (DEC:xs) ((I x):zs) = execute xs ((I (x-1)):zs)
execute (DEC:_) _ = TypeError
execute ((POP i):xs) s = if length s < i then TypeError else execute xs (drop i s)
execute (SWAP:xs) (x:y:zs) = execute xs (y:x:zs)
execute (SWAP:_) _ = TypeError
execute (LEQ:xs) ((I x):(I y):zs) = execute xs ((B (x <= y)):zs)
execute (LEQ:_) _ = TypeError
execute ((IFELSE p1 p2):xs) ((B b):s) = case execute (if b then p1 else p2) s of
    A s' -> execute xs s'
    e -> e
execute ((IFELSE _ _):xs) _ = TypeError

rankP :: Prog -> Rank -> Maybe Rank
rankP [] a = Just a
rankP ((LDI _):xs) a = rankP xs (a+1)
rankP ((LDB _):xs) a = rankP xs (a+1)
rankP (DUP:xs) a = if a < 1 then Nothing else rankP xs (a+1)
rankP (ADD:xs) a = if a < 2 then Nothing else rankP xs (a-1)
rankP (MULT:xs) a = if a < 2 then Nothing else rankP xs (a-1)
rankP (DEC:xs) a = if a < 1 then Nothing else rankP xs a
rankP ((POP i):xs) a = if a < i then Nothing else rankP xs (a-i)
rankP (SWAP:xs) a = if a < 2 then Nothing else rankP xs a
rankP (LEQ:xs) a = if a < 2 then Nothing else rankP xs (a-1)
rankP ((IFELSE p1 p2):xs) a = if a < 1 then Nothing else min <$> rankP p1 (a-1) <*> rankP p2 (a-1) >>= rankP xs

run :: Prog -> Stack -> Result
run p s = case rankP p (length s) of
    Nothing -> RankError
    Just _ -> execute p s
