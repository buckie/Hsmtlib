{- |
Module      : Hsmtlib.Solvers.Altergo
  Module wich has the standard configuration for all altergo Modes and
  provides the initilizing function.
-}
module Hsmtlib.Solvers.Altergo(startAltErgo) where

import           Hsmtlib.Solver                      as Slv
import           Hsmtlib.Solvers.Cmd.OnlineCmd
import           Hsmtlib.Solvers.Cmd.ProcCom.Process
import           Hsmtlib.Solvers.Cmd.ScriptCmd
import           System.IO                           (Handle,
                                                      IOMode (WriteMode),
                                                      openFile)
import           Control.Applicative           as Ctr hiding ((<|>))
import           Control.Monad
import           Data.Functor.Identity

import           SmtLib.Parsers.CommonParsers
import           SmtLib.Syntax.Syntax        as CmdRsp

import           Text.Parsec.Prim              as Prim
import           Text.ParserCombinators.Parsec as Pc


-- All the configurations are the same but have diferent names so if anything
-- changes it's easy to alter its configuration.


altErgoConfigOnline :: SolverConfig
altErgoConfigOnline =
        Config { path = "altergo"
               , version = "1.30"
               }

altErgoConfigScript :: SolverConfig
altErgoConfigScript =
        Config { path = "altergo"
               , version = "1.30"
               }

altErgoConfigBatch :: SolverConfig
altErgoConfigBatch =
        Config { path = "altergo"
               , version = "1.30"
               }

stdArgs :: [String]
stdArgs = ["-v"]

{- |
  Function that initialyzes a altergo Solver.
  It Receives a Mode, an SMT Logic, it can receive a diferent configuration
  for the solver and an anternative path to create the script in Script Mode.

  In Online Mode if a FilePath is passed then it's ignored.
-}
startAltErgo :: Mode
             -> String
             -> Maybe SolverConfig
             -> Maybe FilePath
             -> IO Solver

startAltErgo Slv.Online logic sConf _ = startAltErgoOnline logic sConf
startAltErgo Slv.Script logic sConf scriptFilePath =
    startAltErgoScript logic sConf scriptFilePath

-- Start altergo Online.

startAltErgoOnline :: String -> Maybe SolverConfig -> IO Solver
startAltErgoOnline logic Nothing =
  startAltErgoOnline' logic altErgoConfigOnline
startAltErgoOnline logic (Just conf) = startAltErgoOnline' logic conf

startAltErgoOnline' :: String -> SolverConfig -> IO Solver
startAltErgoOnline' logic conf = do
  -- Starts a Z4 Process.
  process <- beginProcess (path conf) stdArgs
  --Set Option to print success after accepting a Command.
  _ <- onlineSetOption Altergo process (PrintSuccess True)
  -- Sets the SMT Logic.
  _ <- onlineSetLogic  Altergo process logic
  -- Initialize the solver Functions and return them.
  return $ onlineSolver process

--Start altergo Script.

startAltErgoScript :: String -> Maybe SolverConfig -> Maybe FilePath -> IO Solver
startAltErgoScript logic Nothing Nothing =
    startAltErgoScript' logic altErgoConfigScript "temp.smt2"
startAltErgoScript logic (Just conf) Nothing =
    startAltErgoScript' logic conf "temp.smt2"
startAltErgoScript logic Nothing (Just scriptFilePath) =
    startAltErgoScript' logic altErgoConfigScript scriptFilePath
startAltErgoScript logic (Just conf) (Just scriptFilePath) =
    startAltErgoScript' logic conf scriptFilePath

{-
  In this function a file is created where the commands are kept.

  Every function in the ScriptCmd Module needs a ScriptConf data which has:

  - sHandle: The handle of the script file
  - sCmdPath: The Path to initilyze the solver
  - sArgs: The options of the solver
  - sFilePath: The file path of the script so it can be passed to the solver
               when started.
-}
startAltErgoScript' :: String -> SolverConfig -> FilePath -> IO Solver
startAltErgoScript' logic conf scriptFilePath = do
  scriptHandle <- openFile scriptFilePath WriteMode
  let srcmd = newScriptArgs conf scriptHandle scriptFilePath
  _ <- scriptSetOption srcmd (PrintSuccess True)
  _ <- scriptSetLogic srcmd logic
  return $ scriptSolver srcmd

--Function which creates the ScriptConf for the script functions.
newScriptArgs :: SolverConfig  -> Handle -> FilePath -> ScriptConf
newScriptArgs solverConfig nHandle scriptFilePath =
  ScriptConf { sHandle = nHandle
             , sCmdPath = path solverConfig
             , sArgs = stdArgs
             , sFilePath  = scriptFilePath
             }



-- parsing the results of altergo's checksat in online mode (not compliant)

parseCheckSatResponseAlt :: ParsecT String u Identity CheckSatResponse
parseCheckSatResponseAlt =
    (string "sat" >> return Sat) <|>
    (string "unsat" >> return Unsat) <|>
    (string "unknown (sat)" >> return Unknown)

parseCmdCheckSatResponseAlt :: ParsecT String u Identity CmdResponse
parseCmdCheckSatResponseAlt = liftM  CmdCheckSatResponse parseCheckSatResponseAlt

onlineCheckSatAlt ::Solvers -> Process  -> IO Result
onlineCheckSatAlt solver proc =
    onlineCheckSatResponseAlt proc CheckSat solver


onlineCheckSatResponseAlt :: Process -> Command -> Solvers -> IO Result
onlineCheckSatResponseAlt proc cmd solver =
    liftA checkSatResponseAlt (onlineFun proc cmd solver)

checkSatResponseAlt :: String -> Result
checkSatResponseAlt stg =
    case result of
        Left err ->  ComError $ stg ++  " | " ++ show  err
        Right cmdRep ->  CCS cmdRep
    where result = parse parseCheckSatResponseAlt "" stg

-- parsing the results of altergo's checksat in script mode (not compliant)

scriptCheckSatResponseAlt :: ScriptConf -> Command -> IO Result
scriptCheckSatResponseAlt conf cmd =
  liftA checkSatResponseAlt  (scriptFunExec conf cmd)

scriptCheckSatAlt :: ScriptConf -> IO Result
scriptCheckSatAlt sConf = scriptCheckSatResponseAlt sConf CheckSat



-- Creates the functions for online mode with the process already running.
-- Each function will send the command to the solver and wait for the response.
onlineSolver :: Process -> Solver
onlineSolver process =
  Solver { setLogic = onlineSetLogic Altergo process
         , setOption = onlineSetOption Altergo process
         , setInfo = onlineSetInfo Altergo process
         , declareSort = onlineDeclareSort Altergo process
         , defineSort = onlineDefineSort Altergo process
         , declareFun = onlineDeclareFun Altergo process
         , defineFun = onlineDefineFun Altergo process
         , push = onlinePush Altergo process
         , pop = onlinePop Altergo process
         , assert = onlineAssert Altergo process
         , checkSat = onlineCheckSatAlt Altergo process
         , getAssertions = onlineGetAssertions Altergo process
         , getValue = onlineGetValue Altergo process
         , getProof = onlineGetProof Altergo process
         , getUnsatCore = onlineGetUnsatCore Altergo process
         , getInfo = onlineGetInfo Altergo process
         , getOption = onlineGetOption Altergo process
         , exit = onlineExit process
         }

-- Creates the funtion for the script mode.
-- The configuration of the file is passed.
scriptSolver :: ScriptConf -> Solver
scriptSolver srcmd =
  Solver { setLogic = scriptSetLogic srcmd
         , setOption = scriptSetOption srcmd
         , setInfo = scriptSetInfo srcmd
         , declareSort = scriptDeclareSort srcmd
         , defineSort = scriptDefineSort srcmd
         , declareFun = scriptDeclareFun srcmd
         , defineFun = scriptDefineFun srcmd
         , push = scriptPush srcmd
         , pop = scriptPop srcmd
         , assert = scriptAssert srcmd
         , checkSat = scriptCheckSatAlt srcmd
         , getAssertions = scriptGetAssertions srcmd
         , getValue = scriptGetValue srcmd
         , getProof = scriptGetProof srcmd
         , getUnsatCore = scriptGetUnsatCore srcmd
         , getInfo = scriptGetInfo srcmd
         , getOption = scriptGetOption srcmd
         , exit = scriptExit srcmd
         }
