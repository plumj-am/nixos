#!/usr/bin/env nix-shell
#!nix-shell -i runghc -p "haskell.packages.ghc9103.ghcWithPackages (p: [p.typed-process])" --impure
module Rebuild where

import           Data.Char            (isSpace)
import           Data.List            (dropWhileEnd)
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

rebuilderTag :: String
rebuilderTag = purple "[Rebuilder] "

nixEvalArgs :: [String]
nixEvalArgs =
   [ "eval"
   , "--raw"
   , ".#nixosConfigurations"
   , "--apply"
   , "x: builtins.concatStringsSep \",\" (builtins.attrNames x)"
   ]

printTagged :: String -> IO ()
printTagged msg = putStrLn $ rebuilderTag ++ msg

splitCommas :: String -> [String]
splitCommas [] = []
splitCommas xs =
   case break (== ',') xs of
      (chunk, [])       -> [chunk]
      (chunk, _ : rest) -> chunk : splitCommas rest

numberLines :: [String] -> [String]
numberLines = zipWith (\i x -> "  " ++ show i ++ ". " ++ x) [1 ..]

availableHosts :: IO [String]
availableHosts = splitCommas <$> readProcess "nix" nixEvalArgs ""

listHosts :: IO ()
listHosts = availableHosts >>= putStrLn . unlines . numberLines

getHostname :: IO String
getHostname = dropWhileEnd isSpace <$> readProcess "hostname" [] ""

nhArgs :: String -> [String]
nhArgs host =
   [ "os"
   , "switch"
   , ".#nixosConfigurations." ++ host
   , "--accept-flake-config"
   , "--bypass-root-check"
   , "--builders=null"
   , "--"
   , "--fallback"
   ]

nhCommand :: IO (String, [String])
nhCommand = maybe fallback toNh <$> findExecutable "nh"
  where
   fallback = ("sudo", ["nix", "run", "nixpkgs#nh", "--"])
   toNh path = ("sudo", [path])

rebuild :: String -> IO ()
rebuild host = do
   printTagged $ "Rebuilding " ++ host
   (cmd, prefixArgs) <- nhCommand
   code <- runProcess $ proc cmd $ prefixArgs ++ nhArgs host
   handleExitCode code host

handleExitCode :: ExitCode -> String -> IO ()
handleExitCode ExitSuccess host = printTagged $ "Rebuild succeeded for " ++ host
handleExitCode code@(ExitFailure _) host = do
   printTagged $ "Rebuild failed for " ++ host
   exitWith code

main :: IO ()
main = do
   args <- getArgs
   case args of
      [x]
         | isLocal x -> rebuild =<< getHostname
         | isRemote x -> die $ missingArgVal "--remote [hostname]"
         | isList x -> listHosts
         | isHelp x -> putStr usage
      [x, host] | isRemote x -> die $ notImplemented "--remote"
      _ -> die $ invalidInput args
  where
   isLocal s = s `elem` ["--local", "-local", "-l"]
   isRemote s = s `elem` ["--remote", "-remote", "-r"]
   isList s = s `elem` ["--list", "-list", "-L"]
   isHelp s = s `elem` ["--help", "-help", "-h"]

missingArgVal :: String -> String
missingArgVal arg = "Required value for '" ++ arg ++ "' not provided!\n\n" ++ usage

invalidInput :: [String] -> String
invalidInput input =
   unlines
      [ "Invalid input from user:"
      , ""
      , unlines $ numberLines input
      , "See correct usage below:"
      , ""
      , usage
      ]

notImplemented :: String -> String
notImplemented cmd = unlines ["Command '" ++ cmd ++ "' not yet implemented!", "", usage]

usage :: String
usage =
   unlines
      [ "PlumJam's NixOS System Rebuilder"
      , ""
      , "Usage:"
      , purple "  rebuild " ++ blue "--local " ++ "             Rebuild the current host"
      , purple "  rebuild " ++ blue "--remote" ++ " [hostname]  Rebuild a remote host"
      , ""
      , "Arguments:"
      , blue "  --local (-l) " ++ "                Rebuild the current host"
      , blue "  --remote (-r)" ++ " [hostname]     Remote host to rebuild [optional]"
      , blue "  --list (-L)  " ++ "                List the available hosts"
      , blue "  --help (-h)  " ++ "                Print this help output"
      ]
