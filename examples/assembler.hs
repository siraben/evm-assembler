{-# LANGUAGE NoMonomorphismRestriction #-}
module Assembler where
import Data.Function hiding (fix)
import Data.List
import Text.Read
infixl :$:
  
-- Combinator code
data CODE = Y
          | B
          | C
          | K
          | S
          | T
          | Re
          | ADD
          | MUL
          | SUB
          | EQL
          | I
          | H Int
          | RET
          | Lit String
          | CODE :$: CODE
          deriving Show


data LC = Ze | Su LC | Pass Ast | La LC | App LC LC deriving Show
data Type = TC String | TV String | TAp Type Type deriving Show
data Pred = Pred String Type deriving Show

data Ast
  = R CODE     -- raw combinator assembly
  | V String     -- variable
  | A Ast Ast    -- application
  | L String Ast -- lambda abstraction
  | Proof Pred   -- proof for typeclass instantiation?
  deriving Show


-- De Bruijn encoding of lambda calculus terms
--        z    s       lift ast   abs.   app.
-- data LC = Ze | Su LC | Pass Ast | La LC | App LC LC

-- Convert the AST into a nameless representation
-- debruijn :: [String] -> Ast ->  LC
debruijn n e = case e of
  R s     -> pure $ Pass (R s)
  V v     -> pure $ foldr (\h m -> if (h == v) then Ze else (Su m)) (Pass (V v)) n
  A x y   -> App <$> debruijn n x <*> debruijn n y
  L s t   -> La <$> debruijn (s:n) t
  Proof _ -> Nothing


-- See Kiselyov's paper - "Lambda to SKI, semantically", pages 10 - 11
--         V       C            N          W
data Sem = Defer | Closed Ast | Need Sem | Weak Sem
-- ($$) algorithm

-- ($$), case Defer
-- Parameters: babsa == self
-- (V, V)   -> N (C S.(S $! I $! I))
ldef Defer      = Need (Closed (A (A (R S) (R I)) (R I)))
-- (V, C d) -> N (C S.(kC $! kI $! d))
ldef (Closed d) = Need (Closed (A (R T) d))
-- (V, N e) -> N (C S.(kS $! kI) $$ e)
ldef (Need e)   = Need (babsa (Closed (A (R S) (R I))) e)
-- (V, W e) -> N (C (S.(kS $! kI)) $$ e)
ldef (Weak e)   = Need (babsa (Closed (R T)) e)


-- ($$), case Closed
-- d is the argument to Closed (i.e. lclo (Closed d) y = ...)
-- (C d, V)     -> N (C d)
lclo d Defer       = Need (Closed d)
-- (C d1, C d2) -> C (S.(d1 $! d2))
lclo d (Closed dd) = Closed (A d dd)
-- (C d, N e)   -> N (C S.(kB $! d) $$ e)
lclo d (Need e)    = Need (babsa (Closed (A (R B) d)) e)
-- (C d, W e)   -> W (C d $$ e)
lclo d (Weak e)    = Weak (babsa (Closed d) e)


-- ($$), case Need
-- e is the argument to Need (i.e. lnee babsa (Need e) y = ...)
-- (N e, V)     -> N (C S.kS $$ e $$ C S.kI)
lnee e Defer      = Need (babsa (babsa (Closed (R S)) e) (Closed (R I)))
-- (N e, C d)   -> N (C S.(kC $! kC $! d) $$ e)
lnee e (Closed d) = Need (babsa (Closed (A (R Re) d)) e)
-- (N e1, N e2) -> N ((C S.kS) $$ e1 $$ e2)
lnee e (Need ee)  = Need (babsa (babsa (Closed (R S)) e) ee)
-- (N e1, W e2) -> N ((C S.kC) $$ e1 $$ e2)
lnee e (Weak ee)  = Need (babsa (babsa (Closed (R C)) e) ee)

-- ($$), case Weak
-- e is the argument to Weak (i.e. lweak babsa (Weak e) y = ...)
-- (W e, V)     -> N e
lwea e Defer      = Need e
-- (W e, C d)   -> W (e $$ C d)
lwea e (Closed d) = Weak (babsa e (Closed d))
-- (W e1, N e2) -> N ((C S.kB) $$ e1 $$ e2)
lwea e (Need ee)  = Need (babsa (babsa (Closed (R B)) e) ee)
-- (W e1, W e2) -> W (e1 $$ e2)
lwea e (Weak ee)  = Weak (babsa e ee)

-- ($$), the full thing.
babsa :: Sem -> Sem -> Sem
babsa Defer      y = ldef y
babsa (Closed d) y = lclo d y
babsa (Need e)   y = lnee e y
babsa (Weak e)   y = lwea e y


-- Full bracket abstraction algorithm, from De Bruijn to combinators
babs :: LC -> Sem
-- let z : (a*y, a) repr = V
babs Ze = Defer
-- let s: (b*y, a) repr -> (_*(b*y), a) repr = fun e -> W e
  -- Looks like this version recurs on e.
babs (Su e) = Weak (babs e)
-- A lifted AST is closed.
babs (Pass s) = Closed s
babs (La t) =
  -- See "lam" function on page 10 of Kiselyov
  -- Lambda abstraction
  case babs t of
    -- V     -> C S.kI
    Defer    -> Closed (R I)
    -- C d   -> C S.(kK $! d)
    -- Remark: d is a closed body of a lambda abstraction, so the
    -- variable being abstracted over is not used and thus we can
    -- use the K combinator
    Closed d -> Closed (A (R K) d)
    -- N e   -> e
    Need e   -> e
    -- W e   -> (C S.kK) $$ e
    Weak e   -> babsa (Closed (R K)) e

  -- Application
babs (App x y) = babsa (babs x) (babs y)


-- Convert an AST into debruijn form, then perform bracket abstraction,
-- return if and only if we have a closed form.
nolam :: Ast -> Maybe Ast
nolam x = do x <- debruijn [] x
             case babs x of
               Closed d -> Just d
               _        -> Nothing



-- Expressions, with static typing thanks to tagless-final.
class BoolSYM repr where
  bool :: Bool -> repr Bool
  eqn :: repr Int -> repr Int -> repr Bool
  if_ :: repr Bool -> repr a -> repr a -> repr a

class ExpSYM repr where
  int :: Int -> repr Int
  add :: repr Int -> repr Int -> repr Int
  sub :: repr Int -> repr Int -> repr Int
  mul :: repr Int -> repr Int -> repr Int

class Symantics repr where
  lam :: (repr a -> repr b) -> repr (a -> b)
  app :: repr (a -> b) -> repr a -> repr b

class FixSYM repr where
  fix :: (repr a -> repr a) -> repr a

-- Interpreter
newtype E a = E { unE :: a }
instance ExpSYM E where
  int = E
  add (E l) (E r) = E (l + r)
  sub (E l) (E r) = E (l - r)
  mul (E l) (E r) = E (l * r)

instance BoolSYM E where
  bool = E
  eqn (E l) (E r) = E (l == r)
  if_ (E p) c a = if p then c else a

instance Symantics E where
  lam f = E (\a -> unE (f (E a)))
  app (E f) (E x) = E (f x)

instance FixSYM E where
  fix f = f (fix f)
  
newtype Comp a = Comp { unComp :: CODE }

compile = (:$: RET) . unComp

instance ExpSYM Comp where
  int i = Comp (H i)
  add (Comp l) (Comp r) = Comp (r :$: (l :$: ADD))
  mul (Comp l) (Comp r) = Comp (r :$: (l :$: MUL))
  sub (Comp l) (Comp r) = Comp (r :$: (l :$: SUB))

instance BoolSYM Comp where
  bool True = Comp (I :$: K)
  bool False = Comp (K :$: I)
  eqn (Comp l) (Comp r) = Comp (r :$: (l :$: EQL))
  if_ (Comp p) (Comp c) (Comp a) = Comp ((p :$: c) :$: a)

-- instance Symantics Comp where
--   lam f = Comp (unComp (f (Comp I)))
--   app (Comp f) (Comp x) = Comp (f :$: x)

instance FixSYM Comp where
  fix f = f (Comp Y)
-- Remainder: make Comp an instance of Symantics, making it
-- Turing-complete.

fact = fix (\fact -> lam (\n -> if_ (eqn n (int 0))
                                    (int 1)
                                     (mul n (app fact (sub n (int 1))))))

assemble' (f :$: x) k = assemble' f (\f -> assemble' x (\x -> k $ f ++ x ++ ["$"]))
assemble' (H x) k = k ["#", show x, "$"]
assemble' ADD k = k ["++"]
assemble' SUB k = k ["--"]
assemble' EQL k = k ["=="]
assemble' MUL k = k ["**"]
assemble' (Lit v) k = k [v]
assemble' Re k = k ["R"]
assemble' x k = k [show x]
 
assemble c = assemble' c id
           & unwords

bin op = B :$: T :$: (T :$: op)
plus = bin ADD
