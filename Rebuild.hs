#!/usr/bin/env nix-shell
#!nix-shell -i runghc -p "haskell.packages.ghc9103.ghcWithPackages (p: [p.typed-process])" --impure
{-# LANGUAGE OverloadedStrings #-}
module Rebuild where

import           Data.Text            (Text)
import qualified Data.Text            as T
import qualified Data.Text.IO         as TIO
import           System.Directory     (findExecutable, getHomeDirectory,
                                       setCurrentDirectory)
import           System.Environment   (getArgs)
import           System.Exit          (ExitCode (ExitFailure, ExitSuccess), die,
                                       exitWith)
import           System.Process       (readProcess)
import           System.Process.Typed (proc, runProcess)

reset :: Text
reset = "\ESC[0m"

purple, blue :: Text -> Text
purple msg = "\ESC[35m" <> msg <> reset
blue msg = "\ESC[34m" <> msg <> reset

rebuilderTag :: Text
rebuilderTag = purple "[Rebuilder] "

nixEvalArgs :: [Text]
nixEvalArgs =
   [ "eval"
   , "--raw"
   , ".#nixosConfigurations"
   , "--apply"
   , "x: builtins.concatStringsSep \",\" (builtins.attrNames x)"
   ]

printTagged :: Text -> IO ()
printTagged msg = TIO.putStrLn $ rebuilderTag <> msg

numberLines :: [Text] -> [Text]
numberLines = zipWith (\i x -> "  " <> T.pack (show i) <> ". " <> x) [1 ..]

availableHosts :: IO [Text]
availableHosts = T.split (== ',') . T.stripEnd . T.pack <$> readProcess "nix" (map T.unpack nixEvalArgs) ""

listHosts :: IO ()
listHosts = availableHosts >>= TIO.putStrLn . T.unlines . numberLines

getHostname :: IO Text
getHostname = T.stripEnd . T.pack <$> readProcess "hostname" [] ""

nixExperimentalFeatures :: Text
nixExperimentalFeatures = "flakes nix-command cgroups pipe-operators"

nhArgs :: Text -> [Text]
nhArgs host =
   [ "os"
   , "switch"
   , ".#nixosConfigurations." <> host
   , "--accept-flake-config"
   , "--bypass-root-check"
   , "--builders=null"
   , "--"
   , "--fallback"
   , "--option"
   , "experimental-features"
   , nixExperimentalFeatures
   ]

nhCommand :: IO (String, [Text])
nhCommand = maybe fallback toNh <$> findExecutable "nh"
  where
   fallback =
      ( "sudo"
      ,
         [ "nix"
         , "--extra-experimental-features"
         , nixExperimentalFeatures
         , "run"
         , "nixpkgs#nh"
         , "--"
         ]
      )
   toNh path = ("sudo", [T.pack path])

rebuild :: Text -> IO ()
rebuild host = do
   printTagged $ "Rebuilding " <> host
   (cmd, prefixArgs) <- nhCommand
   code <- runProcess $ proc cmd $ map T.unpack $ prefixArgs <> nhArgs host
   handleExitCode code host

handleExitCode :: ExitCode -> Text -> IO ()
handleExitCode ExitSuccess host = printTagged $ "Rebuild succeeded for " <> host
handleExitCode code@(ExitFailure _) host = do
   printTagged $ "Rebuild failed for " <> host
   exitWith code

main :: IO ()
main = do
   args <- map T.pack <$> getArgs
   (dir, restArgs) <- parsePathArgs args
   setCurrentDirectory $ T.unpack dir
   case restArgs of
      [x]
         | isLocal x -> rebuild =<< getHostname
         | isRemote x -> die . T.unpack $ missingArgVal "--remote [hostname]"
         | isList x -> listHosts
         | isHelp x -> TIO.putStr usage
      [x, host] | isRemote x -> die . T.unpack $ notImplemented "--remote"
      _ -> die . T.unpack $ invalidInput args

isLocal, isRemote, isList, isHelp, isPath :: Text -> Bool
isLocal s = s `elem` ["--local", "-local", "-l"]
isRemote s = s `elem` ["--remote", "-remote", "-r"]
isList s = s `elem` ["--list", "-list", "-L"]
isHelp s = s `elem` ["--help", "-help", "-h"]
isPath s = s `elem` ["--path", "-path", "-p"]

parsePathArgs :: [Text] -> IO (Text, [Text])
parsePathArgs args =
   case break isPath args of
      (before, []) -> (\home -> (T.pack home <> "/nixos", before)) <$> getHomeDirectory
      (before, _ : dir : after) -> pure (dir, before ++ after)
      (before, _) -> die . T.unpack $ invalidInput args

missingArgVal :: Text -> Text
missingArgVal arg = "Required value for '" <> arg <> "' not provided!\n\n" <> usage

invalidInput :: [Text] -> Text
invalidInput input =
   T.unlines
      [ "Invalid input from user:"
      , ""
      , T.unlines $ numberLines input
      , "See correct usage below:"
      , ""
      , usage
      ]

notImplemented :: Text -> Text
notImplemented cmd = T.unlines ["Command '" <> cmd <> "' not yet implemented!", "", usage]

{- FOURMOLU_DISABLE -}
usage :: Text
usage =
   T.unlines
      [ "PlumJam's NixOS System Rebuilder"
      , ""
      , "Usage:"
      , purple "  rebuild " <> blue "--local " <> "                           Rebuild the current host"
      , purple "  rebuild " <> blue "--remote" <> " [hostname]                Rebuild a remote host"
      , purple "  rebuild " <> blue "--remote" <> " [hostname] " <> blue "--path" <> " [path]  Rebuild a remote host with a custom path"
      , ""
      , "Arguments:"
      , blue "  --path (-p)" <> " [path]        Absolute or relative path to your NixOS config directory (default: $HOME/nixos)"
      , blue "  --local (-l)" <> "              Rebuild the current host"
      , blue "  --remote (-r)" <> " [hostname]  Remote host to rebuild"
      , blue "  --list (-L)" <> "               List the available hosts"
      , blue "  --help (-h)" <> "               Print this help output"
      ]
