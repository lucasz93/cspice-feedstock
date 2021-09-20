#include <stdio.h>
#include "cspice/SpiceUsr.h"
#include "cspice/cspice_state.h"

int main ()
{
	void *state = cspice_alloc();
    printf ("One radian in degrees: %11.6f\n", dpr_c(state) * 1.0);
    cspice_free(state);
    return 0;
}
