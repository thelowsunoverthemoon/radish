#include <stdio.h>
#include <stdlib.h>

#include "fmod/fmod.h"
#include "ntdll/ntdll.h"

#define WIN32_LEAN_AND_MEAN
#include <windows.h>

// compile   : doskey ds=(cl radish.c "ntdll/ntdll_x64.lib" "fmod_vc.lib" "user32.lib" /O2) ^&^& "demo.bat"
// ntdll lib : https://github.com/x64dbg/ScyllaHide/blob/master/3rdparty/ntdll/ntdll.h

// Bugs :
// High CPU usage -> Sleep fixes it but will lag Mouse Events in GOTO loop
// Unfocus creates sticky keys FIXED
// Shift not getting key up events FIXED
// Shift shows 2 keys. This is BY DESIGN. Because there is General Shift, and Directional Shift Key. I give an option in case you just want to detect shift key in general.
// Scroll Wheel doesn't end BY DESIGN

#define IF_ERR_EXIT(status, msg) do {\
    if (!(status)) {\
        fprintf(stderr, "radish error : %s", msg);\
        exit(EXIT_FAILURE);\
    }\
} while(0)
  
#define CHANNEL_NUM       100
#define KEY_SET_MAX       (0xFE + 1)
#define KEY_BUF_MAX       49
#define NULL_TERM_LEN     1
#define SPACE_LEN         1
#define QUOTE_PAIR        2
#define ARG_NUM           3
#define INPUT_NUM         50
#define OUTPUT_BUFFER     "%COMSPEC%\\##########################\\..\\..\\cmd.exe /k " // 123.123.12.12.-123-123-123-123-123-123-123-123-123-123-123-123-
#define INVALID_VAL       -1000 // arg value is highly unlikely to be -1000, maybe change later
#define SOUND_STORE_START 10
#define ENV_READ          260
#define MAX_ARGS          6
#define MAX_LEN           1000
#define COMMAND_ARG       -1

enum sound_type {
    SOUND_EFFECT,
    SOUND_OBJ,
    SOUND_TRACK
};

enum arg_type {
    ARG_INT,
    ARG_STRING,
    ARG_END
};

enum coord_type {
    COORD_NONE,
    COORD_X,
    COORD_Y
};

struct command {
    enum arg_type* args;
    BOOL (*func)(struct param_store*);
};

struct sound {
    FMOD_SOUND* sound;
    FMOD_CHANNEL* chan;
    enum sound_type type;
    int fade_time;
};

struct sound_obj {
	int x;
	int y;
	struct sound sound;
	struct sound_obj* next;
	int id;
};

struct param_store {
    int args[MAX_ARGS];
    
    FMOD_SYSTEM* fmod;
    int rate;
    
    char buffer[MAX_LEN];
    wchar_t buf[ENV_READ];

    HANDLE pipe;
    HANDLE process;
    PROCESS_BASIC_INFORMATION pbi;
    
    struct command* com_param;
    
    int sound_store_cur;
    int sound_store_max;
    struct sound* sound_store;
    
    int obj_id;
    struct sound_obj* obj_list;

    wchar_t* env_buf;
    size_t env_max;
    
    wchar_t* player_x;
    wchar_t* player_y;
    FMOD_VECTOR player_pos;

};

// components
DWORD WINAPI parse_audio( LPVOID lpParam );
VOID update_player_service(PVOID arg, BOOLEAN type);

// audio commands 
BOOL load_object(struct param_store* param);
BOOL load_effect(struct param_store* param);
BOOL load_track(struct param_store* param);
BOOL stop_audio(struct param_store* param);
BOOL set_observer(struct param_store* param);
BOOL play_audio(struct param_store* param);
BOOL create_object(struct param_store* param);

// helpers
int index_to_id(int index);
void set_con_mode(HANDLE std_in);
RTL_USER_PROCESS_PARAMETERS get_rtl_param(HANDLE con, PROCESS_BASIC_INFORMATION pbi);
wchar_t* get_buffer(HANDLE con, PROCESS_BASIC_INFORMATION pbi, size_t* max_len);
int get_env_size(HANDLE process, void* address);
FMOD_SOUND* load_audio(struct param_store* param, FMOD_MODE flags, enum sound_type type);
BOOL parse_args(struct param_store* param, int end, int start, struct command* command, int* arg_num);

int
main(int argc, char* argv[]) {
    IF_ERR_EXIT(argc == ARG_NUM, "invalid argument number");
    
    char* com = calloc(strlen(OUTPUT_BUFFER) + strlen(argv[1]) + QUOTE_PAIR + SPACE_LEN + strlen(argv[2]) + NULL_TERM_LEN, sizeof(char));
    IF_ERR_EXIT(com, "allocation error for commandline buffer");
    sprintf(com, "%s\"%s\" %s", OUTPUT_BUFFER, argv[1], argv[2]);
    
    STARTUPINFO si = {
        .cb = sizeof(si)
    };
    PROCESS_INFORMATION pi = {0};
    IF_ERR_EXIT(
        CreateProcess(
           NULL,
           com,
           NULL,           
           NULL,          
           FALSE,           
           CREATE_NEW_PROCESS_GROUP,         
           NULL, 
           NULL,         
           &si,           
           &pi
        ),
        "error creating new cmd process"
    );

    free(com);
    Sleep(200); // make sure process starts first BEFORE querying info

    PROCESS_BASIC_INFORMATION pbi = {0};
    NtQueryInformationProcess(pi.hProcess, ProcessBasicInformation, &pbi, sizeof(pbi), NULL);

    FMOD_SYSTEM* fmod;
    IF_ERR_EXIT(FMOD_System_Create(&fmod, FMOD_VERSION) == FMOD_OK, "fmod system could not be created");
    IF_ERR_EXIT(FMOD_System_Init(fmod, CHANNEL_NUM, FMOD_INIT_VOL0_BECOMES_VIRTUAL, NULL) == FMOD_OK, "fmod system could not be initialized");
    IF_ERR_EXIT(FMOD_System_SetAdvancedSettings(fmod, &(FMOD_ADVANCEDSETTINGS) {
        .cbSize = sizeof(FMOD_ADVANCEDSETTINGS),
        .vol0virtualvol = 0.001f
    }) == FMOD_OK, "fmod advanced settings could not be set");
    
    int rate;
    IF_ERR_EXIT(FMOD_System_GetSoftwareFormat(fmod, &rate, NULL, NULL) == FMOD_OK, "fmod rate could not be read");
    IF_ERR_EXIT(FMOD_System_Set3DSettings(fmod, 1, 1, 0.3) == FMOD_OK, "fmod 3D settings could not be set");

    size_t max_len;
    wchar_t* buffer = get_buffer(pi.hProcess, pbi, &max_len);
    RTL_USER_PROCESS_PARAMETERS rtl = get_rtl_param(pi.hProcess, pbi);
    IF_ERR_EXIT(WriteProcessMemory(pi.hProcess, rtl.CommandLine.Buffer, buffer, sizeof(wchar_t) * max_len , NULL), "write process memory failed for initial write");

    HANDLE std_in = GetStdHandle(STD_INPUT_HANDLE);
    IF_ERR_EXIT(std_in != INVALID_HANDLE_VALUE, "could not get input handle");
    HANDLE std_out = GetStdHandle(STD_OUTPUT_HANDLE);
    IF_ERR_EXIT(std_out != INVALID_HANDLE_VALUE, "could not get output handle");
    
    set_con_mode(std_in);

    SHORT mouse_x = 0;
    SHORT mouse_y = 0;
    DWORD mouse_b = 0;
    BOOL focus = TRUE;

    BOOL key_set[KEY_SET_MAX] = {0};
    char key_buf[KEY_BUF_MAX + NULL_TERM_LEN] = {
        [0] = '-'
    };

    int written = 0;
    INPUT_RECORD rec[INPUT_NUM] = {0};
    BOOL use_async = FALSE;

    struct param_store param = {
        .process = pi.hProcess,
        .fmod = fmod,
        .pbi = pbi,
        .rate = rate,
        .com_param = (struct command[]) {
            ['E'] = {
                (enum arg_type[]) {ARG_STRING, ARG_END}, load_effect
            },
            ['T'] = {
                (enum arg_type[]) {ARG_STRING, ARG_END}, load_track
            },
            ['O'] = {
                (enum arg_type[]) {ARG_STRING, ARG_END}, load_object
            },
            ['P'] = {
                (enum arg_type[]) {ARG_INT, ARG_INT, ARG_INT, ARG_INT, ARG_END}, play_audio
            },
            ['S'] = {
                (enum arg_type[]) {ARG_INT, ARG_END}, stop_audio
            },
            ['X'] = {
                (enum arg_type[]) {ARG_STRING, ARG_STRING, ARG_END}, set_observer
            },
            ['C'] = {
                (enum arg_type[]) {ARG_INT, ARG_INT, ARG_INT, ARG_END}, create_object
            }
        }
    };
    
    HANDLE update_player;
    IF_ERR_EXIT(
        CreateTimerQueueTimer(&update_player, NULL, update_player_service, &param, 0, 10, WT_EXECUTEDEFAULT), 
        "error creating update player timer queue"
    );
    IF_ERR_EXIT(
        CreateThread(NULL, 0, parse_audio, &param, 0, NULL),
        "error creating audio parse thread"
    );

    param.pipe = CreateNamedPipe(
        "\\\\.\\pipe\\RADISH",
        PIPE_ACCESS_INBOUND,
        PIPE_WAIT | PIPE_TYPE_BYTE | PIPE_READMODE_BYTE,
        1,
        0,
        MAX_LEN,
        NMPWAIT_USE_DEFAULT_WAIT,
        NULL
    );
    IF_ERR_EXIT(param.pipe != INVALID_HANDLE_VALUE, "could not create audio pipe");
    
    while (TRUE) {
        set_con_mode(std_in);
        
        DWORD num_event = 0;
        GetNumberOfConsoleInputEvents(std_in, &num_event);
        if (num_event) {
            DWORD num_read;
            ReadConsoleInputW(std_in, rec, INPUT_NUM, &num_read);
            for (int i = 0; i < num_read; i++) {
                if (rec[i].EventType == MOUSE_EVENT) {
                    mouse_x = rec[i].Event.MouseEvent.dwMousePosition.X;
                    mouse_y = rec[i].Event.MouseEvent.dwMousePosition.Y;
                    
                    CONSOLE_SCREEN_BUFFER_INFO con_info = {0};
                    GetConsoleScreenBufferInfo(std_out, &con_info);
                    SHORT h = con_info.srWindow.Bottom - con_info.srWindow.Top;
                    if (con_info.dwCursorPosition.Y >= h) {
                        mouse_y -= (con_info.dwCursorPosition.Y - h);
                    }                        
                   
                    if (rec[i].Event.MouseEvent.dwEventFlags == MOUSE_WHEELED) {
                        mouse_b = (short) HIWORD(rec[i].Event.MouseEvent.dwButtonState) / 120 * 6; // 6 or -6 for up / down scroll
                    } else {
                        mouse_b = rec[i].Event.MouseEvent.dwButtonState;
                    }
                    
                } else if (rec[i].EventType == KEY_EVENT) {
                    if (rec[i].Event.KeyEvent.dwControlKeyState & SHIFT_PRESSED) {
                        use_async = TRUE;
                    } else {
                        if (use_async == TRUE) {
                            for (int i = 0; i < KEY_SET_MAX; i++) {
                                SHORT state = GetAsyncKeyState(i);
                                key_set[i] = (( 1 << 15 ) & state) ? TRUE : FALSE;
                            }
                        }
                        use_async = FALSE;
                        key_set[rec[i].Event.KeyEvent.wVirtualKeyCode] = rec[i].Event.KeyEvent.bKeyDown;
                    }
                } else if (rec[i].EventType == FOCUS_EVENT) {
                    focus = rec[i].Event.FocusEvent.bSetFocus;
                    if (!focus) {
                        use_async = FALSE;
                        for (int i = 0; i < KEY_SET_MAX; i++) {
                            key_set[i] = FALSE;
                        }
                    }
                }
            }
        }

        char* key_write = key_buf + 1; // 1 = '-'
        memset(key_write, 0, KEY_BUF_MAX);
        for (int i = 0; i < KEY_SET_MAX; i++) {
            if (key_set[i] == TRUE || use_async) {
                if (use_async) {
                    SHORT state = GetAsyncKeyState(i);
                    if (!(( 1 << 15 ) & state)) {
                        continue;
                    }
                }
                key_write += sprintf(key_write, "%d-", i);
                if (key_write - key_buf > KEY_BUF_MAX) {
                    break;
                }
            }
        }

        memset(buffer, 0, sizeof(wchar_t) * written);
        if ((key_write - key_buf) == 1) {
            written = swprintf(buffer, max_len, L"%d.%d.%d", mouse_x, mouse_y, mouse_b);
        } else {
            written = swprintf(buffer, max_len, L"%d.%d.%d.%hs", mouse_x, mouse_y, mouse_b, key_buf);
        }
        RTL_USER_PROCESS_PARAMETERS rtl = get_rtl_param(pi.hProcess, pbi);
        if (written > 0) { 
            IF_ERR_EXIT(
                WriteProcessMemory(pi.hProcess, rtl.CommandLine.Buffer, buffer, sizeof(wchar_t) * (written + NULL_TERM_LEN), NULL),
                "could not write to CMDCMDLINE buffer"
            );
        }
    }
    
    // only way it terminates is through TASKKILL. no need for free / stop anything
    
    return EXIT_SUCCESS;
}

DWORD WINAPI parse_audio(LPVOID arg) {
    struct param_store* param = (struct param_store*) arg;
    while (!param->pipe) {
        Sleep(10);
    }
    
    while (TRUE) {
        if (ConnectNamedPipe(param->pipe, NULL)) {
            DWORD read;
            char* buffer = param->buffer;
            ReadFile(param->pipe, buffer, MAX_LEN, &read, NULL);
            
            if (read > 0) {
                buffer[read - 1] = '\0';
                int i = 0;
                
                while (i < read) {
                    while (buffer[i] != '"') {
                        i++;
                        if (!(i < read)) {
                            goto exit;
                        }
                    }
                    
                    i++;
                    if (!(i < read)) {
                        goto exit;
                    }
                    
                    int start = i;
                    int arg_num = COMMAND_ARG;
                    struct command command;
                    while (buffer[i] != '"') {
                        if (buffer[i] == '#') {
                            if (!parse_args(param, i, start, &command, &arg_num)) {
                                goto exit;
                            }
                            start = i + 1;
                        }
                        i++;
                        if (!(i < read)) {
                            goto exit;
                        }
                    }

                    if (!parse_args(param, i, start, &command, &arg_num)) {
                        goto exit;
                    }
                    if (command.args[arg_num] != ARG_END) {
                        goto exit;
                    }
                    command.func(param);
                    i++;

                }
                exit:;
            }
            DisconnectNamedPipe(param->pipe);
        }
    }
    return 0;
}

BOOL parse_args(struct param_store* param, int end, int start, struct command* command, int* arg_num) {
    param->buffer[end] = '\0';
    if (*arg_num == COMMAND_ARG) {
        *command = param->com_param[(param->buffer + start)[0]];
    } else if (command->args[*arg_num] == ARG_END) {
        return FALSE;
    } else if (command->args[*arg_num] == ARG_INT) {
        param->args[*arg_num] = atoi(param->buffer + start);
    } else if (command->args[*arg_num] == ARG_STRING) {
        param->args[*arg_num] = start;
    }
    (*arg_num)++;
    return TRUE;
}

VOID
update_player_service(PVOID arg, BOOLEAN type) {

    struct param_store* param = (struct param_store*) arg;
    IF_ERR_EXIT(FMOD_System_Update(param->fmod) == FMOD_OK, "fmod could not be updated");
    if (!param->player_x) {
        return;
    }
    
    RTL_USER_PROCESS_PARAMETERS rtl = get_rtl_param(param->process, param->pbi);
    if (rtl.EnvironmentSize > param->env_max) {
        param->env_max = rtl.EnvironmentSize * 2;
        param->env_buf = realloc(param->env_buf, param->env_max);
        IF_ERR_EXIT(param->env_buf, "allocation error for environment buffer");
    }

    wchar_t* buf = param->env_buf;
    IF_ERR_EXIT(ReadProcessMemory(param->process, rtl.Environment, buf, rtl.EnvironmentSize, NULL), "error reading environment memory");

    for (int start = 0, end = 0; buf[end]; end++) {

        start = end;
        while (buf[end] != L'=') {
            end++;
        }

        enum coord_type type = COORD_NONE;
        if (end - start != 0) {
            if (wcsncmp(buf + start, param->player_x, end - start) == 0) {
                type = COORD_X;
            } else if (wcsncmp(buf + start, param->player_y, end - start) == 0) {
                type = COORD_Y;
            }
        }

        end++;
        start = end; 
        while (buf[end]) {
            end++;
        }

        if (type == COORD_X) {
            param->player_pos.x = _wtoi(buf + start);
        } else if (type == COORD_Y) {
            param->player_pos.z = _wtoi(buf + start);
        }
        
    }

    IF_ERR_EXIT(FMOD_System_Set3DListenerAttributes(param->fmod, 0, &param->player_pos, NULL, NULL, NULL) == FMOD_OK, "fmod could not set 3D position");
}

wchar_t* add_var(struct param_store* param, int str) {
    int len = strlen(param->buffer + str) + 1;
    wchar_t* buf = malloc(len * sizeof(wchar_t));
    IF_ERR_EXIT(buf, "allocation error for observer variable");
	MultiByteToWideChar(CP_UTF8, 0, param->buffer + str, -1, buf, len);
	return buf;
}

BOOL set_observer(struct param_store* param) {
    param->player_x = add_var(param, param->args[0]);
    param->player_y = add_var(param, param->args[1]);
    return TRUE;
}

struct sound* get_sound_obj(struct param_store* param, int index, FMOD_VECTOR* vec) {
    struct sound_obj* cur = param->obj_list;
    int id = index_to_id(index);
    while (cur) {
        if (cur->id == id) {
            if (vec) {
                *vec = (FMOD_VECTOR) {cur->x, 0, cur->y};
            }
            return &cur->sound;
        }
        cur = cur->next;
    }
    return NULL;
}

int index_to_id(int index) {
    // check out of bounds
    return -index - 1;
}

void remove_sound_obj(struct param_store* param, int index) {
	struct sound_obj* prev = NULL;
	struct sound_obj* cur = param->obj_list;
    int id = index_to_id(index);
	while (cur) {
		if (cur->id == id) {
			if (cur == param->obj_list) {
				param->obj_list = cur->next;
			} else {
				prev->next = cur->next;
			}
            free(cur);
			return;
		}
		prev = cur;
		cur = cur->next;
	}
}

BOOL
create_object(struct param_store* param) {
    struct sound_obj* new = malloc(sizeof(struct sound_obj));
    IF_ERR_EXIT(new, "allocation error for sound object");
    // check out of bounds
    *new = (struct sound_obj) {
        .x = param->args[1],
        .y = param->args[2],
        .sound = param->sound_store[param->args[0]],
        .next = NULL,
        .id = param->obj_id
    };
    param->obj_id++;
    if (!param->obj_list) {
        param->obj_list = new;
    } else {
        struct sound_obj* prev = NULL;
        struct sound_obj* cur = param->obj_list;
        while (cur) {
            prev = cur;
            cur = cur->next;
        }
        prev->next = new;
    }
    return TRUE;
}

BOOL
load_object(struct param_store* param) {
    FMOD_SOUND* sound = load_audio(param, FMOD_3D | FMOD_LOOP_NORMAL | FMOD_3D_LINEARROLLOFF, SOUND_OBJ);
    IF_ERR_EXIT(FMOD_Sound_Set3DMinMaxDistance(sound, 1.0, 3.0) == FMOD_OK, "fmod culd not set 3D minmax settings");
    return TRUE;   
}

BOOL
load_effect(struct param_store* param) {
    load_audio(param, FMOD_DEFAULT, SOUND_EFFECT);
    return TRUE;
}

BOOL
load_track(struct param_store* param) {
    load_audio(param, FMOD_LOOP_NORMAL | FMOD_2D | FMOD_CREATESTREAM, SOUND_TRACK);
    return TRUE;
}

FMOD_SOUND*
load_audio(struct param_store* param, FMOD_MODE flags, enum sound_type type) {
    FMOD_SOUND* sound;
    IF_ERR_EXIT(FMOD_System_CreateSound(param->fmod, param->buffer + param->args[0], flags, NULL, &sound) == FMOD_OK, "fmod could not create sound");
    
    if (param->sound_store_cur == param->sound_store_max) {
        param->sound_store_max = !param->sound_store_max ? SOUND_STORE_START : param->sound_store_max * 2;
        param->sound_store = realloc(param->sound_store, sizeof(FMOD_SOUND*) * param->sound_store_max);
        IF_ERR_EXIT(param->sound_store, "allocation error for sound storage");
    }
    
    param->sound_store[param->sound_store_cur] = (struct sound) {
        .chan = NULL,
        .type = type,
        .sound = sound,
        .fade_time = 0
    };
    param->sound_store_cur++;
    
    return sound;
}

struct sound* get_sound_from_index(struct param_store* param, int index, FMOD_VECTOR* vec) {
    if (index < 0) {
        return get_sound_obj(param, index, vec);
    } else {
        // check out of bounds
        return &param->sound_store[index];
    }
}

// don't bother checking fmod for below since not crucial

BOOL
play_audio(struct param_store* param) {
    BOOL is_new = FALSE;
    
    FMOD_VECTOR vec;
    struct sound* sound = get_sound_from_index(param, param->args[0], &vec);
    
    FMOD_BOOL is_playing = FALSE;
    FMOD_Channel_IsPlaying(sound->chan, &is_playing);
    FMOD_BOOL is_virtual = FALSE;
    FMOD_Channel_IsVirtual(sound->chan, &is_virtual);
    if (sound->type == SOUND_EFFECT || !is_playing || is_virtual) {
            FMOD_System_PlaySound(param->fmod, sound->sound, NULL, TRUE, &sound->chan);
        if (sound->type == SOUND_EFFECT) {
            FMOD_Channel_SetVolume(sound->chan, param->args[3] / 100.0);
        } else if (sound->type == SOUND_OBJ) {
            FMOD_Channel_Set3DAttributes(sound->chan, &vec, NULL);
        }
        is_new = TRUE;
    }
    
    if (sound->type != SOUND_EFFECT) {
        FMOD_System_LockDSP(param->fmod);
        
        unsigned long long dspclock;
        FMOD_Channel_GetDSPClock(sound->chan, NULL, &dspclock);

        float volumes[2];
        unsigned long long points[2];
        BOOL in_trans = FALSE;
        if (!is_new) { // clear transition
            unsigned int has_trans = 0;
            FMOD_Channel_GetFadePoints(sound->chan, &has_trans, NULL, NULL);
            if (has_trans) {
                FMOD_Channel_GetFadePoints(sound->chan, &has_trans, points, volumes);
                in_trans = dspclock >= points[0] && dspclock < points[1];
                FMOD_Channel_RemoveFadePoints(sound->chan, dspclock, dspclock + (param->rate * sound->fade_time));
            }
        }
        
        if (in_trans) {
            float vol = volumes[0] + ((volumes[1] - volumes[0]) / (points[1] - points[0]) * (dspclock - points[0]));
            FMOD_Channel_AddFadePoint(sound->chan, dspclock, vol);
            FMOD_Channel_AddFadePoint(sound->chan, dspclock + (dspclock - points[0]), param->args[3] / 100.0);
        } else {
            FMOD_Channel_AddFadePoint(sound->chan, dspclock, param->args[1] / 100.0);
            FMOD_Channel_AddFadePoint(sound->chan, dspclock + (param->rate * param->args[2]), param->args[3] / 100.0);
        }
        
        sound->fade_time = param->args[2];
        FMOD_System_UnlockDSP(param->fmod);
        
    }
    
    if (is_new) {
        FMOD_Channel_SetPaused(sound->chan, FALSE);
    }
    return TRUE;
}

BOOL
stop_audio(struct param_store* param) {
    struct sound* sound = get_sound_from_index(param, param->args[0], NULL);
    if (sound->chan && sound->type != SOUND_EFFECT) {
        FMOD_Channel_Stop(sound->chan);
    }

    if (param->args[0] < 0) {
        remove_sound_obj(param, param->args[0]);
    }
    return TRUE;
}

void
set_con_mode(HANDLE std_in) {
    DWORD mode = 0;
    GetConsoleMode(std_in, &mode);
    SetConsoleMode(std_in, ENABLE_MOUSE_INPUT | ENABLE_EXTENDED_FLAGS | (mode & ~ENABLE_QUICK_EDIT_MODE));
}

wchar_t*
get_buffer(HANDLE con, PROCESS_BASIC_INFORMATION pbi, size_t* max_len) {
    RTL_USER_PROCESS_PARAMETERS rtl = get_rtl_param(con, pbi);
    *max_len = rtl.CommandLine.Length / sizeof(wchar_t);
    
    wchar_t* buffer = calloc(*max_len, sizeof(wchar_t));
    IF_ERR_EXIT(buffer, "allocation error for CMDCMDLINE buffer");
    
    return buffer;
}

RTL_USER_PROCESS_PARAMETERS
get_rtl_param(HANDLE con, PROCESS_BASIC_INFORMATION pbi) {
    
    PEB peb = {0};
    IF_ERR_EXIT(ReadProcessMemory(con, pbi.PebBaseAddress, &peb, sizeof(peb), NULL), "error reading PEB struct");
    
    RTL_USER_PROCESS_PARAMETERS rtl = {0};
    IF_ERR_EXIT(ReadProcessMemory(con, peb.ProcessParameters, &rtl, sizeof(rtl), NULL), "error reading rtl struct");
    
    return rtl;
}