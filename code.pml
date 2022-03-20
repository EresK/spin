mtype : States = {processing, act_on, act_off, act_working, wait, reading};

mtype : States st_Controller = processing;
mtype : States st_Actuator = act_off;

mtype : process = { Controller_n, Actuator_n };
chan turn = [1] of {mtype : process}

int await_act = 0;

proctype Controller() {
    do
    :: turn ? Controller_n;
        atomic {
            if
                :: st_Controller == processing -> {
                    printf("Controller act on\n");
                    st_Controller = act_on;
                    turn ! Actuator_n;
                }

                :: st_Controller == act_on -> {
                    st_Controller = act_working;
                    printf("Controller act working\n");
                }

                :: st_Controller == act_working -> {
                    if
                        :: (await_act < 5) -> {
                            printf("%d\n", await_act);
                            await_act = await_act + 1;
                        }

                        :: (await_act >= 5) -> {
                            printf("Controller act off\n");
                            st_Controller = act_off;
                            turn ! Actuator_n;
                            await_act = 0;
                        }
                    fi;
                }

                :: st_Controller == act_off -> {
                    st_Controller = wait;
                    printf("Controller wait\n");
                }

                :: st_Controller == wait -> {
                    st_Controller = reading;
                    printf("Controller reading\n");
                }

                :: st_Controller == reading -> {
                    st_Controller = processing;
                    printf("Controller processing\n");
                }

                :: else -> skip;
            fi;
        }
        turn ! Controller_n;
    od;
}


proctype Actuator() {
    do
    :: turn ? Actuator_n;
        atomic {
            if
                :: st_Controller == act_on -> {
                    st_Actuator = act_on;
                    printf("Turn on actuator\n");
                }

                :: st_Controller == act_off -> {
                    st_Actuator = act_off;
                    printf("Turn off actuator\n");
                }

                else -> skip;
            fi;
        }
    od;
}

init {
    run Controller();
    run Actuator();

    st_Controller = processing;
    st_Actuator = act_off;
    await_act = 0;

    turn ! Controller_n;
}
