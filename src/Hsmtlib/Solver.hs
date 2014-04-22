{- |
Module      : Solver
  This module has most types,data and functions that a user might need to
  utilize the library.
-}
module Hsmtlib.Solver where

import           SMTLib2

{-|
 Placeholder type that later on will be changed to a more complex type.
-}
-- We will parse the result of a solver and return an s-expression.
type Sexp = String


{-|
 Placeholder type that later on will be changed to a more complex type.
-}
type Error = String -- We will change the error to a more informative type.


{-|
 Placeholder type that later on will be changed to a more complex type.
-}
{-
  We still aren't sure what should  be the correct result, maybe a tuple:
  (Sexp, [Error])
-}


data Result = Success
            | Unsupported
            | Error String
            | Sat
            | Unsat
            | Unknown
            | UError String
            deriving (Show)


-- | Sovler's that are currently supported.
data Solvers = Z3 | Cvc4 | Yices | Mathsat | Altergo | Boolector

-- | Avaliable modes to use a solver.
data Mode = Online | Script | Batch

{- |
  Alternative configuration of a solver which can be passed in the function
  startSolver in 'Main'
-}
data SolverConfig =
    Config { path :: String
           , args :: [String]
           }


{-|
 Solver data type that has all the functions.
-}
data Solver = Solver
    { setLogic      :: Name -> IO Result
    , setOption     :: Option -> IO Result
    , setInfo       :: Attr -> IO Result
    , declareType   :: Name -> Integer -> IO Result
    , defineType    :: Name -> [Name] -> Type -> IO Result
    , declareFun    :: Name -> [Type] -> Type -> IO Result
    , defineFun     :: Name -> [Binder] -> Type -> Expr -> IO Result
    , push          :: Integer -> IO Result
    , pop           :: Integer -> IO Result
    , assert        :: Expr -> IO Result
    , checkSat      :: IO Result
    , getAssertions :: IO String
    , getValue      :: [Expr] -> IO String
    , getProof      :: IO String
    , getUnsatCore  :: IO String
    , getInfo       :: InfoFlag -> IO String
    , getOption     :: Name -> IO String
    , exit          :: IO String
    }
    | BSolver
    { executeBatch  :: [Command] -> IO String }




