module Main (main) where

import           Data.List            (isPrefixOf)
import           Data.Maybe           (isJust)
import           System.Directory     (findExecutable)
import           System.Environment   (getArgs)
import           System.Exit          (ExitCode (ExitFailure, ExitSuccess), die,
                                       exitWith)
import           System.Process       (readProcess)
import           System.Process.Typed (proc, runProcess)

-- TYPES

data User = Jam | Root
data Seed = Seed {host :: Host, did :: DID}

userToString :: User -> String
userToString Jam  = "jam"
userToString Root = "root"

stringToUser :: String -> Maybe User
stringToUser "jam"  = Just Jam
stringToUser "root" = Just Root
stringToUser _      = Nothing

newtype Host = Host String
newtype RID = RID String
newtype DID = DID String
newtype DIDRaw = DIDRaw String -- Without did:key: prefix.
newtype RadCmd = RadCmd String
newtype SshCmd = SshCmd String

unHost :: Host -> String
unHost (Host s) = s

unRID :: RID -> String
unRID (RID s) = s

unDID :: DID -> String
unDID (DID s) = s

unDIDRaw :: DIDRaw -> String
unDIDRaw (DIDRaw s) = s

unRadCmd :: RadCmd -> String
unRadCmd (RadCmd s) = s

unSshCmd :: SshCmd -> String
unSshCmd (SshCmd s) = s

-- CONSTANTS

reset :: String
reset = "\ESC[0m"

purple, blue :: String -> String
purple msg = "\ESC[35m" ++ msg ++ reset
blue msg = "\ESC[34m" ++ msg ++ reset

rshTag :: String
rshTag = purple "[RSH] "

tailnetExt :: String
tailnetExt = ".taild29fec.net"

-- NOTE: Need to strip did:key when adding a node to the allow list.
sysSeeds :: [Seed]
sysSeeds =
   [ -- Seed {host = "date", did = ""},
     Seed{host = Host "kiwi", did = DID "did:key:z6MkjPdRVZGSoMnFXL7FtgR7xvdrque51TMRspJ9WAK2gde6"}
   , Seed{host = Host "plum", did = DID "did:key:z6MkffMv6gHyhQQWT1NH8p3X9hiMdxsAnUhtxXTfx2xZSqzz"}
   , Seed{host = Host "sloe", did = DID "did:key:z6MkrBKRwq3ADkck29xhyxSvjWiPs9XXoCLxNCZ2egYSNWCv"}
   , Seed{host = Host "yuzu", did = DID "did:key:z6MkjteiKR9kqhLXnU3oVDDNf3zpoQPnLfMeqZXGsbVJVKeT"}
   ]

userSeeds :: [Seed]
userSeeds =
   [Seed{host = Host "yuzu", did = DID "did:key:z6MkhQJuAftpcYts9YXwY2GH9ig48ke9BN8QyhTZ4C7gU2Un"}]

-- HELPERS

toFQDN :: User -> Host -> String
toFQDN user host = userToString user ++ "@" ++ unHost host ++ tailnetExt

stripDIDPrefix :: DID -> Maybe DIDRaw
stripDIDPrefix (DID s) =
   let prefix = "did:key:"
    in if prefix `isPrefixOf` s
         then Just $ DIDRaw $ drop (length prefix) s
         else Nothing

isCmd :: String -> IO Bool
isCmd cmd = isJust <$> findExecutable cmd -- `isJust` does the same as `maybe False (const True)`.

getSeeds :: [Seed] -> [String]
getSeeds = map (\(Seed{host, did}) -> unHost host ++ ": " ++ unDID did)

getSshCmd :: User -> Host -> SshCmd
getSshCmd user host =
   -- ssh <username/root>@<host> ...
   SshCmd ""

getRadSysSeedCmd :: Host -> RID -> DIDRaw -> RadCmd
getRadSysSeedCmd host rid src =
   -- ssh <user>@<host> "rad-system seed <rid> --from <src>"
   RadCmd ""

getRadUserSeedCmd :: Host -> RID -> DIDRaw -> RadCmd
getRadUserSeedCmd host rid src =
   -- ssh <user>@<host> "rad seed <rid> --from <src>"
   RadCmd ""

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

-- EXECUTORS AND HANDLERS

trustAllSeeds :: [Seed] -> String
trustAllSeeds seeds =
   -- rad id update --title "Allow seeding from <name>.<tailnetExt>:<systemPort>" --allow <did without `did:key:` prefix>
   ""

listSeeds :: IO ()
listSeeds = do
   let systemSeedsList = getSeeds sysSeeds
   let userSeedsList = getSeeds userSeeds
   printTagged $ "SYSTEM SEEDS [" ++ show (length sysSeeds) ++ "]"
   putStrLn . unlines . numberLines $ systemSeedsList
   printTagged $ "USER SEEDS [" ++ show (length userSeeds) ++ "]"
   putStrLn . unlines . numberLines $ userSeedsList

beginSeed :: RID -> IO ()
beginSeed rid = printTagged $ "Seeding " ++ unRID rid

handleExitCode :: ExitCode -> RID -> IO ()
handleExitCode ExitSuccess rid = printTagged $ "Seeding succeeded for " ++ unRID rid
handleExitCode code@(ExitFailure _) rid = do
   printTagged $ "Seeding failed for " ++ unRID rid
   exitWith code

main :: IO ()
main = do
   args <- getArgs
   case args of
      [x]
         | isRid x -> die $ missingArgVal "--rid [rid]"
         | isList x -> listSeeds
         | isHelp x -> putStr usage
      [x, rid] | isRid x -> die $ notImplemented $ RadCmd "--rid"
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
      [ "Invalid input from user:"
      , ""
      , unlines $ numberLines input
      , "See correct usage below:"
      , ""
      , usage
      ]

notImplemented :: RadCmd -> String
notImplemented cmd = unlines ["Command '" ++ unRadCmd cmd ++ "' not yet implemented!", "", usage]

{- FOURMOLU_DISABLE -}
usage :: String
usage =
   unlines
      [ "PlumJam's Radicle Seed Helper",
        "",
        "Usage:",
        purple "  rsh " ++ "[rid]        The Radicle repository ID to seed across all available nodes (see " ++ blue "--list" ++ ")",
        "",
        "Arguments:",
        blue "  --list (-l)  " ++ "    List the available seed nodes",
        blue "  --help (-h)  " ++ "    Print this help output"
      ]
{- FOURMOLU_ENABLE -}
