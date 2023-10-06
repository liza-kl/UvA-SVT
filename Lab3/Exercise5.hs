module Exercise5 where
import Test.QuickCheck
import System.IO.Unsafe
import Data.List
import Mutation

-- ## Task ##
-- Implement function(s) that calculate
-- the conjectures: properties that are equivalent, whose cases are subsets of other properties, etc

-- ## Deliverables ##

-- Implementations, documentation of approach, indication of time spent

-- ## Code Trash ##

-- Estimated Time 200 Mins.

{-

    The way we check for property equivalence is generally by using the "mutate'" function for the different properties we try to compare to.
    Then we just compare the two different boolean lists together and if those two lists are equivalent we assume that the properties are equivalent to each other.
    
    This approach in reality is kind of flawed though, since this implies a dependency of equivalence checking two properties with the tested function (and the amount of mutants), which isn't the case.
    (Most likely... We can't come up with formal proof that if a function changes the property equivalence still stays. But is just feels weird/inelegant to have this dependency, since properties are sort of logical operators and you should be able to check equivalence with each other on a more formal and isolated basis...)
    
    That is due to the way we are doing mutation testing though.
    We are just "swapping" out the function outputs with each other, so in a way we aren't "really mutation testing".
    And this fact we can't really "logically" check if two properties are equivalent (without using the function) to each other kind of abuses this fact.
    This is since all of the generated metrics aren't really mutation testing metrics but just "output swapping metrics", how strong the properties are in that regard and the limited data type (of just Integers).
    Therefore we can't really test for real equivalence, since we have no way to show it. (Without some really scuffed AST or source code manipulation, to do real mutation testing. Ain't nobody got time for that, I guess...)

    So in reality you would need to check up on property equivalence in a different, more logic-based way way.
    We can't really do that here though.
    So we just compare the mutated output lists for equivalence.

    We create a map with the property and it's mutation tested output and then combine properties together, which have the same boolean maps (mutation survivors/kills).

    From this we can create a list, which contain lists of properties which are equal to each other by mapping them together and have a list of equivalent properties.
    Based on that we can also check for property subsets. We use the same approach as in exercise 3. So see exercise 3 for subset generation.

-}

-- Get all equivalent properties based on a function and a mutator. (We check for equal mutation survivor/kill results)
-- We get the mutation results and then map equal properties together to a list.
getEquivalentProperties:: [([Integer] -> Integer -> Bool)] -> (Integer -> [Integer]) -> ([Integer] -> Gen [Integer]) -> Integer -> [[([Integer] -> Integer -> Bool)]]
getEquivalentProperties properties function mutator amount = mapEqualProperties (getBooleanTablesOfProperties properties function mutator amount)

-- Generates the mutation survival/kill results for a given list of properties.
getBooleanTablesOfProperties:: [([Integer] -> Integer -> Bool)] -> (Integer -> [Integer]) -> ([Integer] -> Gen [Integer]) -> Integer -> [(([Integer] -> Integer -> Bool), Gen [Bool])]
getBooleanTablesOfProperties [] function mutator amount = []
getBooleanTablesOfProperties (x:xs) function mutator amount = (x, (mutate' mutator [x] function amount)) : (getBooleanTablesOfProperties xs function mutator amount)

-- Mapping of equivalent property sets.
mapEqualProperties:: [(([Integer] -> Integer -> Bool), Gen [Bool])] -> [[([Integer] -> Integer -> Bool)]]
mapEqualProperties propertyTables = map (map fst) (groupPropertyTables propertyTables)

-- Groups together properties with the same boolean mutation result table.
-- So... About that unsafe IO thing. You see those types? I needed way too much time trying to get everything 100% correct.
-- Yes. I could slap on an IO-Monad onto everywhere, since at this point we aren't in the "pure Haskell domain" anyways, and re-implement standard-functions like the "groupBy".
-- I spent way too much time and sanity on this exercise though and at this point I am just happy that it seems working.
-- So this was a deliberate choice to optimise, both for functionality and most amount of sanity left.
-- If you were to do this better, as mentioned, one could add IO monads everywhere and re-implement the necessary functions to work with their corresponding IO variants.
-- Now please excuse me... I need to go to the next punching bag. 
groupPropertyTables:: [(([Integer] -> Integer -> Bool), Gen [Bool])] -> [[(([Integer] -> Integer -> Bool), Gen [Bool])]]
groupPropertyTables propertyTables = groupBy (\(_, a) (_, b) -> unsafePerformIO(isMutationStatusEquivalent a b)) propertyTables

-- Equivalence function. We define two properties as equal if their mutation status lists (result from mutate' function) are equal.
isMutationStatusEquivalent:: Gen [Bool] -> Gen [Bool] -> IO Bool
isMutationStatusEquivalent gen1 gen2 = do
    mutationStatus1 <- generate gen1
    mutationStatus2 <- generate gen2
    return (mutationStatus1 == mutationStatus2)

-- Takes a list of already equivalent properties and then generates a map which contains the equivalent property set and their property subsets.
-- In theory we could also apply other kinds of derived set "operations", (by modifying the "subsequences x" part)
-- (see FitSpec paper), like an implication as well. But right now, we want a conjecture, thus needing the subsequences. 
calculateSubsetsOfEquivalentProperties:: [[([Integer] -> Integer -> Bool)]] -> [([([Integer] -> Integer -> Bool)], [[([Integer] -> Integer -> Bool)]])]
calculateSubsetsOfEquivalentProperties [] = []
calculateSubsetsOfEquivalentProperties (x:xs) = (x, subsequences x) : calculateSubsetsOfEquivalentProperties xs

-- And finally calculate the conjecture based upon equivalence check and subset generation.
calculateConjecture:: [([Integer] -> Integer -> Bool)] -> (Integer -> [Integer]) -> ([Integer] -> Gen [Integer]) -> Integer -> [([([Integer] -> Integer -> Bool)], [[([Integer] -> Integer -> Bool)]])]
calculateConjecture properties function mutator amount = calculateSubsetsOfEquivalentProperties (getEquivalentProperties properties function mutator amount)