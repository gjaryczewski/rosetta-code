-- ES5 Iterative

var doors = [];

for (var i = 0; i < 100; i++)
    doors[i] = false;

for (var i = 1; i<= 100; i++)
    for (var i2 = i - 1, g; i2<100; i2+=i)
        doors[i2] =! doors[i2];

for (var i = 1; i <= 100; i++)
    console.log("Door %d is %s", i, doors[i-1] ? "open" : "closed");

-- ES5 Functional Composition, Naive search

(function (n) {
    "use strict";
    function finalDoors(n) {
        var lstRange = range(1, n);
        return lstRange
            .reduce(function (a, _, k) {
                var m = k + 1;
                return a.map(function (x, i) {
                    var j = i + 1;
                    return [j, j % m ? x[1] : !x[1]];
                });
            }, zip(
                lstRange,
                replicate(n, false)
            ));
    };
    function zip(xs, ys) {
        return xs.length === ys.length ? (
            xs.map(function (x, i) {
                return [x, ys[i]];
            })
        ) : undefined;
    }
    function replicate(n, a) {
        var v = [a],
            o = [];
        if (n < 1) return o;
        while (n > 1) {
            if (n & 1) o = o.concat(v);
            n >>= 1;
            v = v.concat(v);
        }
        return o.concat(v);
    }
    function range(m, n, delta) {
        var d = delta || 1,
            blnUp = n > m,
            lng = Math.floor((blnUp ? n - m : m - n) / d) + 1,
            a = Array(lng),
            i = lng;
        if (blnUp)
            while (i--) a[i] = (d * i) + m;
        else
            while (i--) a[i] = m - (d * i);
        return a;
    }
    return finalDoors(n)
        .filter(function (tuple) {
            return tuple[1];
        })
        .map(function (tuple) {
            return {
                door: tuple[0],
                open: tuple[1]
            };
        });
 
})(100);

-- Optimized (iterative)

for (var door = 1; door <= 100; door++) {
    var sqrt = Math.sqrt(door);
    if (sqrt === (sqrt | 0)) {
      console.log("Door %d is open", door);
    }
  }

-- Simple for loop

for(var door=1;i<10/*Math.sqrt(100)*/;i++){
    console.log("Door %d is open",i*i);
   }

-- Optimized (functional)
-- The question of which doors are flipped an odd number of times reduces to the question of which numbers have an odd number of integer factors. We can simply search for these:

(function (n) {
    "use strict";
    return range(1, 100)
        .filter(function (x) {
            return integerFactors(x)
                .length % 2;
        });
    function integerFactors(n) {
        var rRoot = Math.sqrt(n),
            intRoot = Math.floor(rRoot),
            lows = range(1, intRoot)
            .filter(function (x) {
                return (n % x) === 0;
            });
        return lows.concat(lows.map(function (x) {
                return n / x;
            })
            .reverse()
            .slice((rRoot === intRoot) | 0));
    }
    function range(m, n, delta) {
        var d = delta || 1,
            blnUp = n > m,
            lng = Math.floor((blnUp ? n - m : m - n) / d) + 1,
            a = Array(lng),
            i = lng;
        if (blnUp)
            while (i--) a[i] = (d * i) + m;
        else
            while (i--) a[i] = m - (d * i);
        return a;
    }
})(100);

-- ES6 (1)

Array.apply(null, { length: 100 })
  .map((v, i) => i + 1)
    .forEach(door => { 
      var sqrt = Math.sqrt(door); 
 
      if (sqrt === (sqrt | 0)) {
        console.log("Door %d is open", door);
      } 
    });

-- ES6 (2)

// Array comprehension style
[ for (i of Array.apply(null, { length: 100 })) i ].forEach((_, i) => { 
  var door = i + 1
  var sqrt = Math.sqrt(door); 
 
  if (sqrt === (sqrt | 0)) {
    console.log("Door %d is open", door);
  } 
});
