#!/usr/bin/env nix-shell
#!nix-shell -i runghc -p "haskell.packages.ghc9103.ghcWithPackages (p: [p.typed-process])" --impure

import           Data.Maybe           (listToMaybe)
import qualified Data.Text            as T
import           System.Directory     (findExecutable)
import           System.Environment   (getArgs)
import           System.Exit          (ExitCode (ExitFailure, ExitSuccess), die,
                                       exitWith)
import           System.Process       (readProcess)
import           System.Process.Typed (proc, runProcess)

purple, blue, reset :: String
purple = "\ESC[35m"
blue = "\ESC[34m"
reset = "\ESC[0m"

rebuilderTag :: String
rebuilderTag = purple ++ "[Rebuilder] " ++ reset

nixEvalArgs :: [String]
nixEvalArgs =
   [ "eval",
     "--raw",
     ".#nixosConfigurations",
     "--apply",
     "x: builtins.concatStringsSep \",\" (builtins.attrNames x)"
   ]

printer :: String -> IO ()
printer msg = putStrLn $ rebuilderTag ++ msg

splitOnSep :: String -> String -> [String]
splitOnSep sep = map T.unpack . T.splitOn (T.pack sep) . T.pack

prefixLineNr :: [String] -> [String]
prefixLineNr = zipWith (\i x -> "  " ++ show i ++ ". \"" ++ x ++ "\"") [1 ..]

availableHosts :: IO [String]
availableHosts = splitOnSep "," <$> readProcess "nix" nixEvalArgs ""

listHosts :: IO ()
listHosts = availableHosts >>= putStrLn . unlines . prefixLineNr

getHostname :: IO String
getHostname = maybe (die "Invalid hostname") return . listToMaybe . lines =<< readProcess "hostname" [] ""

nhArgs :: String -> [String]
nhArgs host =
   [ "os",
     "switch",
     ".#nixosConfigurations." ++ host,
     "--accept-flake-config",
     "--bypass-root-check",
     "--builders=null",
     "--",
     "--fallback"
   ]

nhCommand :: IO (String, [String])
nhCommand = maybe fallback toNh <$> findExecutable "nh"
  where
   fallback = ("sudo", ["nix", "run", "nixpkgs#nh", "--"])
   toNh path = ("sudo", [path])

rebuild :: String -> IO ()
rebuild host = do
   printer $ "Rebuilding " ++ host
   (cmd, prefixArgs) <- nhCommand
   code <- runProcess $ proc cmd $ prefixArgs ++ nhArgs host
   handleResult code host

handleResult :: ExitCode -> String -> IO ()
handleResult ExitSuccess host = printer $ "Rebuild succeeded for " ++ host
handleResult code@(ExitFailure _) host = do
   printer $ "Rebuild failed for " ++ host
   exitWith code

main :: IO ()
main = do
   args <- getArgs
   case args of
      [x] | x `elem` ["--local", "-local", "-l"] -> rebuild =<< getHostname
      [x, host] | x `elem` ["--remote", "-remote", "-r"] -> die $ notImplemented "--remote"
      [x] | x `elem` ["--list", "-list", "-L"] -> listHosts
      [x] | x `elem` ["--help", "-help", "-h"] -> putStr usage
      _ -> die $ invalidInput args

invalidInput :: [String] -> String
invalidInput input =
   unlines
      [ "Invalid input from user:",
        "",
        unlines $ prefixLineNr input,
        "See correct usage below:",
        "",
        usage
      ]

notImplemented :: String -> String
notImplemented cmd = unlines ["Command '" ++ cmd ++ "' not yet implemented!", "", usage]

usage :: String
usage =
   unlines
      [ "PlumJam's NixOS System Rebuilder",
        "",
        "Usage:",
        purple ++ "  rebuild " ++ blue ++ "--local " ++ reset ++ "              Rebuild the current host",
        purple ++ "  rebuild " ++ blue ++ "--remote" ++ reset ++ " [hostname]   Rebuild a remote host",
        "",
        "Arguments:",
        blue ++ "  --local (-l) " ++ reset ++ "                 Rebuild the current host",
        blue ++ "  --remote (-r)" ++ reset ++ " [hostname]      Remote host to rebuild [optional]",
        blue ++ "  --list (-L)  " ++ reset ++ "                 List the available hosts",
        blue ++ "  --help (-h)  " ++ reset ++ "                 Print this help output"
      ]
