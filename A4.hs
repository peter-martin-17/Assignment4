module WeatherStats where

import Control.Exception (IOException)
import qualified Control.Exception as Exception
import qualified Data.Foldable as Foldable
import qualified System.Exit as Exit

import Data.ByteString.Lazy (ByteString)
import qualified Data.ByteString.Lazy as ByteString

import Data.Csv
  ( DefaultOrdered(headerOrder)
  , FromField(parseField)
  , FromNamedRecord(parseNamedRecord)
  , Header
  , ToField(toField)
  , ToNamedRecord(toNamedRecord)
  , (.:)
  , (.=)
  )
import qualified Data.Csv as Cassava

import Data.Text (Text)
import qualified Data.Text.Encoding as Text

import Data.Vector (Vector)
import qualified Data.Vector as Vector

data Observation = 
   Observation 
     { day :: Text
     , hourOfDay :: Text
     , temperature :: Float
     , precipitation :: Float
     , windspeed :: Float
     } 
   deriving (Eq, Show)

temp (Observation _ _ t _ _) = t
hour (Observation _ h _ _ _) = h 

instance FromNamedRecord Observation where    
   parseNamedRecord m = 
     Observation 
       <$> m.: "Date"
       <*> m.: "Time"
       <*> m.: "Temp" 
       <*> m.: "Precip"
       <*> m.: "Wind"

decodeItems :: ByteString -> Either String (Vector Observation)
decodeItems = fmap snd . Cassava.decodeByName

decodeItemsFromFile :: FilePath -> IO (Either String (Vector Observation))

decodeItemsFromFile filePath = catchShowIO (ByteString.readFile filePath) >>= return . either Left decodeItems

catchShowIO :: IO a -> IO (Either String a)

catchShowIO action = fmap Right action `Exception.catch` handleIOException
  where 
    handleIOException :: IOException -> IO (Either String a)
    handleIOException = return . Left . show

-- Function to simply read the data. Note that any errors during reading of the csv file will stop the program. To debug file I/O, call dcodeItemsFromFile directly
readData filename = do 
  x <- decodeItemsFromFile filename
  case x of 
     Left reason -> return []
     Right obsData -> return (Vector.toList obsData)

--------------------------------------------
-- DO NOT CHANGE ANYTHING ABOVE THIS LINE --
--------------------------------------------
-- Name: Nickolas Millett
-- Partner: Peter Martin
--------------------------------------------

-- Question 1a

average :: [Float] -> Float
average floatList = (foldl1 (+) (floatList)) / (fromIntegral (length floatList))

-- Question 1b

maxDiff :: [Float]->Float
maxDiff y = maximum y-minimum y

-- Question 1c

daySummary :: Int -> [Observation] -> (Int, Float, Float, Float, Float)
daySummary day obsData = (day, average (map temp (take 24 (drop (24*(day-1)) obsData))), maxDiff (map temp (take 24 (drop (24*(day-1)) obsData))), average (map windSpeed (take 24 (drop (24*(day-1)) obsData))), maxDiff (map windSpeed (take 24 (drop (24*(day-1)) obsData))))

--- any other functions you need for 1a-1c go here
windSpeed (Observation _ _ _ _ w) = w

-- Question 2a
chunkby :: [a]->Int->[[a]]
chunkby l n = 
  if (length l) == 0 then []
  else
    (take n l):(chunkby (drop n l) n )

-- Question 2b

chunkByDays :: [a]->[[a]]
chunkByDays l  = (chunkby (l) 24)


-- 3a: add type declaration here

dailyTemperatureStat :: ([Float]->t)->Int->[Observation]->t

-- 3a: add an explanation

{-
dailyTemperatureStat takes a function that takes a list of floats and outputs a generic type "t", integer, and a list of 
observations as parameters. It outputs a generic type "t". The output is generic because in the function definition, the function
"f" wraps around the entire expression, so whatever that function outputs is dailyTemperatureStat's output. This nested function has
to take a list of floats because that is what its parameter "map temp dayList" returns. A list of Observation has to be inputted
instead of a list of generic type because there is a function, temp, that can only be done on a list of Observation
in the "dayList = (take 24 (drop h obsData))" line".
-}

dailyTemperatureStat f day obsData = f (map temp dayList)  
  where 
    h = 24*(day-1)
    dayList = (take 24 (drop h obsData))

-- Example function for 3b: Computes the minimum temperature for Jan 3 based on the 24 hourly measurements
jan3Minimum filename = do 
  obsData <- readData filename
  let result = minimum (map temp (take 24 (drop 48 obsData)))
  putStr "minimum temperature on January 3 = "
  print (result)

-- Question 3b

allMinimumTemp filename = do 
  obsData <- readData filename
  let result = [(day, (dailyTemperatureStat minimum day obsData)) | day <- [1..365]]
  putStr "Minimum temperature for each day of the year:"
  print (result)


-- Question 3c

{-highDifferentialDays filename = do
  obsData <- readData filename
  let result = [(day, (dailyTemperatureStat maxDiff day obsData), (dailyTemperatureStat average day obsData)) | day <- [1..365], (dailyTemperatureStat maxDiff day obsData) > 15.0)]
  print (result)-}

-- EC
{-Here are the modifications made to the highDifferentialDays in 3c. The code for 3c is commented out because the extra credit code
is the same functon. The function now filters out hours that are less or equal to -99.9 degrees. Also, there is a guard in the
list comprehension that requires the day to have at least a quarter (6) of its data still present after the filtering. If this
condition is not met, the function does not include that day in its list of tuples. This was implemented because there were
days that had only -99.9 degree temperature for each hour (which cannot be calculated with the filter), and days with very little
temperatures that were above -99.9 degrees.-}

highDifferentialDays filename = do
  obsData <- readData filename
  let result = [(day, (maxDiff (filter (>(-99.9)) (map temp (take 24 (drop (24*(day-1)) obsData))))), (average (filter (>(-99.9)) (map temp (take 24 (drop (24*(day-1)) obsData)))))) | day <- [1..365], (length (filter (>(-99.9)) (map temp (take 24 (drop (24*(day-1)) obsData))))) > 5,  ((dailyTemperatureStat maxDiff day obsData) > 15.0)]
  print (result)