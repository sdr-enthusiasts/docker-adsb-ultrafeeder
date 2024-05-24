/*
---------------------------------------------------------------------------------------------
Copyright (C) 2002-2022, Chris Veness
Adaptations Copyright (C) 2023, John Norrbin (JohnEx)
Adaptations (C) 2023, Ramon F. Kolb (kx1t)

MIT License:

Permission is hereby granted, free of charge, to any person 
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without 
restriction, including without limitation the rights to use, 
copy, modify, merge, publish, distribute, sublicense, and/or 
sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following 
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
THE USE OR OTHER DEALINGS IN THE SOFTWARE.
---------------------------------------------------------------------------------------------
*/
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define PI 3.14159265

// https://www.movable-type.co.uk/scripts/latlong.html
double distance(double lat_a, double lon_a, double lat_b, double lon_b)
{

    double lat_a_scaled = lat_a * (double)PI / 180.0;
    double lat_b_scaled = lat_b * (double)PI / 180.0;
    double lat_delta = (lat_b - lat_a) * (double)PI / 180.0;
    double lon_delta = (lon_b - lon_a) * (double)PI / 180.0;

    double a = sin(lat_delta / 2.0) * sin(lat_delta / 2.0) + cos(lat_a_scaled) * cos(lat_b_scaled) * sin(lon_delta / 2.0) * sin(lon_delta / 2.0);
    double c = 2.0 * atan2(sqrt(a), sqrt(1.0 - a));

    return 6372797.56085 * c;
}


int main(int argc, char *argv[])
{
    if (argc != 5)
    {
        printf("Usage: distance lat1 lon1 lat2 lon2\n");
        return 1;
    }

    double lat1 = atof(argv[1]);
    double lon1 = atof(argv[2]);
    double lat2 = atof(argv[3]);
    double lon2 = atof(argv[4]);

    double d = distance(lat1, lon1, lat2, lon2);
    printf("%f\n", d);
    return 0;
}
