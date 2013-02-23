module Main where

import System.Environment
import Scanner
import Text.Parsec
import Text.Parsec.Pos
import Text.Parsec.String

help = "Usage:\n         Parse [option] [files]\n\n"++
            "-h, --help  -> This usage document.\n"++
            "-s          -> Display scanner output only.\n"++
            "Default     -> Full run on files."

type OurParser a b = GenParser Token a b

{- Grammar -}
-- F -> TF | <EOF>
f = do{ x<-t; y<-f; return (x++y) }
    <|> do{ x<-parseEOF <?> "end of file"; return x }
-- T -> (S)
t = do{ x<-parseLeftParen <?> "("; updateState(4+); y<-s; updateState(subtract 4);
        z<-parseRightParen <?> ")"; return (x++y++z) }
-- S -> (A | atomB
s = do{ x<-parseLeftParen <?> "("; updateState(4+); y<-a; return (x++y) }
    <|> do{ x<-parseAtom <?> "atom"; y<-b; return (x++y) }
-- A -> )B | S)B
a = do{ updateState(subtract 4); x<-parseRightParen <?> ")"; y<-b; return (x++y) }
    <|> do{ x<-s; updateState(subtract 4); y<-parseRightParen <?> ")"; z<-b; return (x++y++z) }
-- B -> S | Empty
b = do{x<-s; return x}
    <|> return "" -- epsilon

{- Parsers -}
parseLeftParen = do
    i <- getState
    mytoken (\t -> case t of LeftParen  -> Just(indent i++"(\n")
                             other      -> Nothing)
parseRightParen = do
    i <- getState
    mytoken (\t -> case t of RightParen -> Just(indent i++")\n")
                             other      -> Nothing)
parseAtom = do
    i <- getState
    mytoken (\t -> case t of EOF        -> Nothing
                             LeftParen  -> Nothing
                             RightParen -> Nothing
                             other      -> Just(indent i++show t++"\n"))
parseEOF = do
    mytoken (\t -> case t of EOF        -> Just"<EOF>\n"
                             other      -> Nothing)
{- Helpers -}
mytoken test = tokenPrim show update_pos test

update_pos pos _ _ = newPos "" 0 0

indent n = take n (repeat ' ')

{- main -}
main = do
    args <- getArgs
    case args of
        [] -> putStrLn help
        "-h":_ -> putStrLn help
        "--help":_ -> putStrLn help
        "-s":files -> flip mapM_ files $ \file -> do
                putStrLn ("\n\n"++file)
                contents <- readFile file
                mapM_ putStrLn (map show $ lexer contents)
        _ ->    flip mapM_ args $ \file -> do
                    putStrLn ("\n\n"++file)
                    contents <- readFile file
                    case (runParser f 0 file $ lexer contents) of
                        Left err -> print err
                        Right xs -> putStr xs