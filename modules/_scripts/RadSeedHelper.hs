#!/usr/bin/env nix-shell
#!nix-shell -i runghc -p "haskell.packages.ghc9103.ghcWithPackages (p: [p.typed-process])" --impure
module RadSeedHelper where

import           Data.Char            (isSpace)
import           Data.List            (dropWhileEnd, map)
import           System.Directory     (findExecutable)
import           System.Environment   (getArgs)
import           System.Exit          (ExitCode (ExitFailure, ExitSuccess), die,
                                       exitWith)
import           System.Process       (readProcess)
import           System.Process.Typed (proc, runProcess)

reset :: String
reset = "\ESC[0m"

purple, blue :: String -> String
purple msg = "\ESC[35m" ++ msg ++ reset
blue msg = "\ESC[34m" ++ msg ++ reset

tailnetExt :: String
tailnetExt = ".taild29fec.net"

rshTag :: String
rshTag = purple "[RSH] "

availableSystemSeeds :: [(String, String)]
availableSystemSeeds =
   [ ("plum", "did:key:z6MkffMv6gHyhQQWT1NH8p3X9hiMdxsAnUhtxXTfx2xZSqzz"),
     ("kiwi", "did:key:z6MkjPdRVZGSoMnFXL7FtgR7xvdrque51TMRspJ9WAK2gde6"),
     ("sloe", "did:key:z6MkjPdRVZGSoMnFXL7FtgR7xvdrque51TMRspJ9WAK2gde6"),
     ("yuzu", "did:key:z6MkjteiKR9kqhLXnU3oVDDNf3zpoQPnLfMeqZXGsbVJVKeT")
   ]

availableSystemSeeds' :: [String]
availableSystemSeeds' = map (\(name, did) -> name ++ ": " ++ did) availableSystemSeeds

printTagged :: String -> IO ()
printTagged msg = putStrLn $ rshTag ++ msg

splitCommas :: String -> [String]
splitCommas [] = []
splitCommas xs =
   case break (== ',') xs of
      (chunk, [])       -> [chunk]
      (chunk, _ : rest) -> chunk : splitCommas rest

numberLines :: [String] -> [String]
numberLines = zipWith (\i x -> "  " ++ show i ++ ". " ++ x) [1 ..]

listSeeds :: IO ()
listSeeds = putStrLn . unlines . numberLines $ availableSystemSeeds'

getHostname :: IO String
getHostname = dropWhileEnd isSpace <$> readProcess "hostname" [] ""

seed :: String -> IO ()
seed rid = do
   printTagged $ "Seeding " ++ rid

handleExitCode :: ExitCode -> String -> IO ()
handleExitCode ExitSuccess rid = printTagged $ "Seeding succeeded for " ++ rid
handleExitCode code@(ExitFailure _) rid = do
   printTagged $ "Seeding failed for " ++ rid
   exitWith code

main :: IO ()
main = do
   args <- getArgs
   case args of
      [x]
         | isRid x -> die $ missingArgVal "--rid [rid]"
         | isList x -> listSeeds
         | isHelp x -> putStr usage
      [x, rid] | isRid x -> die $ notImplemented "--rid"
      _ -> die $ invalidInput args
  where
   isRid s = s `elem` ["--rid", "-rid", "-r"]
   isList s = s `elem` ["--list", "-list", "-l"]
   isHelp s = s `elem` ["--help", "-help", "-h"]

missingArgVal :: String -> String
missingArgVal arg = "Required value for '" ++ arg ++ "' not provided!\n\n" ++ usage

invalidInput :: [String] -> String
invalidInput input =
   unlines
      [ "Invalid input from user:",
        "",
        unlines $ numberLines input,
        "See correct usage below:",
        "",
        usage
      ]

notImplemented :: String -> String
notImplemented cmd = unlines ["Command '" ++ cmd ++ "' not yet implemented!", "", usage]

usage :: String
usage =
   unlines
      [ "PlumJam's Radicle Seed Helper",
        "",
        "Usage:",
        purple "  rsh " ++ " [rid]  The Radicle repository ID to seed across all listed nodes",
        "",
        "Arguments:",
        blue "  --list (-L)  " ++ "                List the available seeders",
        blue "  --help (-h)  " ++ "                Print this help output"
      ]
