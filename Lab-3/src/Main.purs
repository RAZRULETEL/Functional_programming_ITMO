module Main where

import Prelude

import Effect (Effect)
import Effect.Console (log)
import Node.Process (argv)
import Data.Number (fromString)
import Data.Maybe (Maybe(..), fromMaybe)
import Effect.Ref (new, read, write) as Ref
import Data.String.Pattern (Pattern(..))
import Node.ReadLine (close, createConsoleInterface, lineH, noCompletion, prompt, setPrompt)
import Node.EventEmitter (on_)
import Data.String.Common (joinWith, split, trim)
import Data.Tuple (Tuple(..), fst, snd)
import Interpolation (calcSplitDifference, linearInterpolate, newtonInterpolate)
import Data.Show (show)
import Data.Monoid (mempty) as List
import Data.List (length, snoc, toUnfoldable)
import Data.Array as Array
import Data.List.Types (List)
import Data.Number.Format (fixed, toStringWith)

defaultStep :: Number
defaultStep = 1.0

getArgOrDefault :: Int -> Array String -> Number -> Number
getArgOrDefault i args default = fromMaybe default $ fromString $ fromMaybe "" (Array.index args i)

printPointsArray :: List (Tuple Number Number) -> Effect Unit
printPointsArray points =
  do
  log $ joinWith "\t" $ toUnfoldable $ map (toStringWith (fixed 2)) $ map fst points
  log $ joinWith "\t" $ toUnfoldable $ map (toStringWith (fixed 2)) $ map snd points

main :: Effect Unit
main = do

  args <- argv

  let frequency = getArgOrDefault 2 args defaultStep

  log $ show args
  log $ "Sampling frequency: " <> (show frequency)

  points <- Ref.new List.mempty
  interface <- createConsoleInterface noCompletion
  setPrompt "> " interface
  interface # on_ lineH \s ->
    if s == "quit" then close interface
    else do
      old <- Ref.read points

      let arr = map (\el -> fromString el) $ split (Pattern " ") $ trim s
      let x = fromMaybe Nothing (Array.index arr 0)
      let y = fromMaybe Nothing (Array.index arr 1)

      let
        point = case Tuple x y of
          (Tuple (Just xv) (Just yv)) -> Just $ Tuple xv yv
          _ -> Nothing

      case point of
        Nothing -> log $ "Wrong input, you must enter two numbers splitted by space"
        (Just tuple) -> do
          let newPoints = (snoc old tuple)

          Ref.write newPoints points
          log $ "You typed: " <> show tuple <> ", total points: " <> (show $ length newPoints)

          let linear = linearInterpolate newPoints frequency
          when (length linear > 0)
            do
            log $ "\nLinear interpolation:"
            printPointsArray linear

          let newton = newtonInterpolate newPoints frequency
          when (length newton > 0) do
            log $ "\nNewton interpolation:"
            printPointsArray newton
      prompt interface
  prompt interface