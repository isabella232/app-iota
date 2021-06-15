#include "ui.h"
#include <string.h>
#include "os_io_seproxyhal.h"
#include "ux.h"
#include "api.h"
#include "iota/addresses.h"

#define TICKS_PER_SECOND 10

// Seconds until UI timeout if expected inputs are not received
#define UI_TIMEOUT_SECONDS 3
#define UI_TIMEOUT_INTERACTIVE_SECONDS 100

static uint16_t timer;

void ui_force_draw()
{
    UX_WAIT_DISPLAYED();
}

void ui_timeout_tick()
{
    // timer not started
    if (timer <= 0) {
        return;
    }

    timer--;
    if (timer == 0) {
        // throw an exception so that a result is always returned
        THROW(SW_COMMAND_TIMEOUT);
    }
}

void ui_timeout_start(bool interactive)
{
    if (interactive) {
        timer = UI_TIMEOUT_INTERACTIVE_SECONDS * TICKS_PER_SECOND;
    }
    else {
        timer = UI_TIMEOUT_SECONDS * TICKS_PER_SECOND;
    }
}

void ui_timeout_stop()
{
    timer = 0;
}
