// Copyright (c) 2021 KNpTrue and homekit-bridge contributors
//
// Licensed under the MIT License.
// You may not use this file except in compliance with the License.
// See [CONTRIBUTORS.md] for the list of homekit-bridge project authors.
//
// Copyright (c) 2015-2019 The HomeKit ADK Contributors
//
// Licensed under the Apache License, Version 2.0 (the “License”);
// you may not use this file except in compliance with the License.
// See [CONTRIBUTORS.md] for the list of HomeKit ADK project authors.

#include <stdio.h>

#include <app.h>
#include <pal/hap.h>

#include <HAP.h>
#include <HAPPlatform+Init.h>
#include <HAPPlatformAccessorySetup+Init.h>
#include <HAPPlatformBLEPeripheralManager+Init.h>
#include <HAPPlatformKeyValueStore+Init.h>
#include <HAPPlatformMFiTokenAuth+Init.h>
#include <HAPPlatformRunLoop+Init.h>
#if IP
#include <HAPPlatformServiceDiscovery+Init.h>
#include <HAPPlatformTCPStreamManager+Init.h>
#endif

#if HAVE_MFI_HW_AUTH
#include <HAPPlatformMFiHWAuth+Init.h>
#endif

#include <signal.h>
static bool requested_factory_reset = false;
static bool clear_pairings = false;

#ifndef BRIDGE_WORK_DIR
#error Please set the macro "BRIDGE_WORK_DIR"
#endif

/**
 * Global platform objects.
 * Only tracks objects that will be released in deinit_platform.
 */
static struct {
    HAPPlatformKeyValueStore keyValueStore;
    HAPAccessoryServerOptions hapAccessoryServerOptions;
    HAPPlatform hapPlatform;
    HAPAccessoryServerCallbacks hapAccessoryServerCallbacks;

    /* Client context pointer. Will be passed to callbacks. */
    void* _Nullable context;

#if HAVE_NFC
    HAPPlatformAccessorySetupNFC setupNFC;
#endif

#if IP
    HAPPlatformTCPStreamManager tcpStreamManager;
#endif

#if HAVE_MFI_HW_AUTH
    HAPPlatformMFiHWAuth mfiHWAuth;
#endif
    HAPPlatformMFiTokenAuth mfiTokenAuth;
} platform;

/**
 * HomeKit accessory server that hosts the accessory.
 */
static HAPAccessoryServerRef accessoryServer;

static void handle_update_state(HAPAccessoryServerRef* _Nonnull server, void* _Nullable context);

/**
 * Initialize global platform objects.
 */
static void init_platform() {
    // Key-value store.
    HAPPlatformKeyValueStoreCreate(
            &platform.keyValueStore, &(const HAPPlatformKeyValueStoreOptions) { .rootDirectory = ".HomeKitStore" });
    platform.hapPlatform.keyValueStore = &platform.keyValueStore;

    // Accessory setup manager. Depends on key-value store.
    static HAPPlatformAccessorySetup accessorySetup;
    HAPPlatformAccessorySetupCreate(
            &accessorySetup, &(const HAPPlatformAccessorySetupOptions) { .keyValueStore = &platform.keyValueStore });
    platform.hapPlatform.accessorySetup = &accessorySetup;

    pal_hap_acc_setup_gen(&platform.keyValueStore, platform.hapPlatform.accessorySetup);

#if IP
    // TCP stream manager.
    HAPPlatformTCPStreamManagerCreate(
            &platform.tcpStreamManager,
            &(const HAPPlatformTCPStreamManagerOptions) {
                    .interfaceName = NULL,        // Listen on all available network interfaces.
                    .port = kHAPNetworkPort_Any,  // Listen on unused port number from the ephemeral port range.
                    .maxConcurrentTCPStreams = PAL_HAP_IP_SESSION_STORAGE_NUM_ELEMENTS });
    platform.hapPlatform.ip.tcpStreamManager = &platform.tcpStreamManager;

    // Service discovery.
    static HAPPlatformServiceDiscovery serviceDiscovery;
    HAPPlatformServiceDiscoveryCreate(
            &serviceDiscovery,
            &(const HAPPlatformServiceDiscoveryOptions) {
                    0 /* Register services on all available network interfaces. */
            });
    platform.hapPlatform.ip.serviceDiscovery = &serviceDiscovery;
#endif

#if (BLE)
    // BLE peripheral manager. Depends on key-value store.
    static HAPPlatformBLEPeripheralManagerOptions blePMOptions = { 0 };
    blePMOptions.keyValueStore = &platform.keyValueStore;

    static HAPPlatformBLEPeripheralManager blePeripheralManager;
    HAPPlatformBLEPeripheralManagerCreate(&blePeripheralManager, &blePMOptions);
    platform.hapPlatform.ble.blePeripheralManager = &blePeripheralManager;
#endif

#if HAVE_MFI_HW_AUTH
    // Apple Authentication Coprocessor provider.
    HAPPlatformMFiHWAuthCreate(&platform.mfiHWAuth);
    platform.hapPlatform.authentication.mfiHWAuth = &platform.mfiHWAuth;
#endif

    // Software Token provider. Depends on key-value store.
    HAPPlatformMFiTokenAuthCreate(
            &platform.mfiTokenAuth,
            &(const HAPPlatformMFiTokenAuthOptions) { .keyValueStore = &platform.keyValueStore });

    // Run loop.
    HAPPlatformRunLoopCreate(&(const HAPPlatformRunLoopOptions) { .keyValueStore = &platform.keyValueStore });

    platform.hapAccessoryServerOptions.maxPairings = kHAPPairingStorage_MinElements;

    platform.hapPlatform.authentication.mfiTokenAuth =
            HAPPlatformMFiTokenAuthIsProvisioned(&platform.mfiTokenAuth) ? &platform.mfiTokenAuth : NULL;

    platform.hapAccessoryServerCallbacks.handleUpdatedState = handle_update_state;
    platform.hapAccessoryServerCallbacks.handleSessionAccept = app_accessory_server_handle_session_accept;
    platform.hapAccessoryServerCallbacks.handleSessionInvalidate = app_accessory_server_handle_session_invalidate;
}

/**
 * Deinitialize global platform objects.
 */
static void deinit_platform() {
#if HAVE_MFI_HW_AUTH
    // Apple Authentication Coprocessor provider.
    HAPPlatformMFiHWAuthRelease(&platform.mfiHWAuth);
#endif

#if IP
    // TCP stream manager.
    HAPPlatformTCPStreamManagerRelease(&platform.tcpStreamManager);
#endif

    // Run loop.
    HAPPlatformRunLoopRelease();
}

/**
 * Restore platform specific factory settings.
 */
void restore_platform_factory_settings(void) {
}

/**
 * Either simply passes State handling to app, or processes Factory Reset
 */
void handle_update_state(HAPAccessoryServerRef* _Nonnull server, void* _Nullable context) {
    if (HAPAccessoryServerGetState(server) == kHAPAccessoryServerState_Idle && requested_factory_reset) {
        HAPPrecondition(server);

        HAPError err;

        HAPLogInfo(&kHAPLog_Default, "A factory reset has been requested.");

        // Purge app state.
        err = HAPPlatformKeyValueStorePurgeDomain(&platform.keyValueStore, ((HAPPlatformKeyValueStoreDomain) 0x00));
        if (err) {
            HAPAssert(err == kHAPError_Unknown);
            HAPFatalError();
        }

        // Reset HomeKit state.
        err = HAPRestoreFactorySettings(&platform.keyValueStore);
        if (err) {
            HAPAssert(err == kHAPError_Unknown);
            HAPFatalError();
        }

        // Restore platform specific factory settings.
        restore_platform_factory_settings();

        // De-initialize App.
        app_release();

        requested_factory_reset = false;

        // Re-initialize App.
        app_create(server, &platform.keyValueStore);

        // Restart accessory server.
        app_accessory_server_start();
        return;
    } else if (HAPAccessoryServerGetState(server) == kHAPAccessoryServerState_Idle && clear_pairings) {
        HAPError err;
        err = HAPRemoveAllPairings(&platform.keyValueStore);
        if (err) {
            HAPAssert(err == kHAPError_Unknown);
            HAPFatalError();
        }
        app_accessory_server_start();
    } else {
        app_accessory_server_handle_update_state(server, context);
    }
}

static const char *help = \
    "usage: %s [options]\n"
    "options:\n"
    "  -d           set the scripts directory\n"
    "  -e           set the entry script name\n"
    "  -h, --help   display this help and exit\n";

static const char *progname = "homekit-bridge";
static const char *scripts_dir = BRIDGE_WORK_DIR;
static const char *entry = BRIDGE_LUA_ENTRY_DEFAULT;

static void usage(const char* message) {
    if (message) {
        if (*message == '-') {
            fprintf(stderr, "%s: unrecognized option '%s'\n", progname, message);
        } else {
            fprintf(stderr, "%s: %s\n", progname, message);
        }
    }
    fprintf(stderr, help, progname);
}

static void doargs(int argc, char *argv[]) {
    if (argv[0] && *argv[0] != 0) {
        progname = argv[0];
    }
    for (int i = 1; i < argc; i++) {
        if (HAPStringAreEqual(argv[i], "-h") || HAPStringAreEqual(argv[i], "--help")) {
            usage(NULL);
            exit(EXIT_SUCCESS);
        } else if (HAPStringAreEqual(argv[i], "-d")) {
            scripts_dir = argv[++i];
            if (!scripts_dir || *scripts_dir == 0 || (*scripts_dir == '-' && scripts_dir[1] != 0)) {
                usage("'-d' needs argument");
                exit(EXIT_FAILURE);
            }
        } else if (HAPStringAreEqual(argv[i], "-e")) {
            entry = argv[++i];
            if (!entry || *entry == 0 || (*entry == '-' && entry[1] != 0)) {
                usage("'-e' needs argument");
                exit(EXIT_FAILURE);
            }
        } else {
            usage(argv[i]);
            exit(EXIT_FAILURE);
        }
    }
}

int main(int argc, char *argv[]) {
    HAPAssert(HAPGetCompatibilityVersion() == HAP_COMPATIBILITY_VERSION);

    // Parse arguments.
    doargs(argc, argv);

    // Initialize global platform objects.
    init_platform();

    // Run lua entry.
    size_t attribute_cnt = app_lua_run(scripts_dir, entry);
    HAPAssert(attribute_cnt);

#if IP
    pal_hap_init_ip(&platform.hapAccessoryServerOptions, attribute_cnt);
#endif

#if BLE
    pal_hap_init_ble(&platform.hapAccessoryServerOptions, attribute_cnt);
#endif

    // Perform Application-specific initalizations such as setting up callbacks
    // and configure any additional unique platform dependencies
    app_init(&platform.hapAccessoryServerOptions, &platform.hapPlatform,
        &platform.hapAccessoryServerCallbacks, &platform.context);

    // Initialize accessory server.
    HAPAccessoryServerCreate(
            &accessoryServer,
            &platform.hapAccessoryServerOptions,
            &platform.hapPlatform,
            &platform.hapAccessoryServerCallbacks,
            platform.context);

    // Create app object.
    app_create(&accessoryServer, &platform.keyValueStore);

    // Start accessory server for App.
    app_accessory_server_start();

    // Run main loop until explicitly stopped.
    HAPPlatformRunLoopRun();
    // Run loop stopped explicitly by calling function HAPPlatformRunLoopStop.

    // Cleanup.
    app_release();

    HAPAccessoryServerRelease(&accessoryServer);

    app_deinit();

#if IP
    pal_hap_deinit_ip(&platform.hapAccessoryServerOptions);
#endif

#if BLE
    pal_hap_deinit_ble(&platform.hapAccessoryServerOptions);
#endif

    // Close lua state.
    app_lua_close();

    deinit_platform();

    return 0;
}
