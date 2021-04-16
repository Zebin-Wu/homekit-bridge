# directory
set(ADK_DIR "${TOP_DIR}/ext/HomeKitAdk")
set(ADK_INC_DIR "${ADK_DIR}/HAP"
                "${ADK_DIR}/PAL"
                "${ADK_DIR}/External/Base64"
                "${ADK_DIR}/External/JSON"
                "${ADK_DIR}/External/HTTP")
set(ADK_PAL_LINUX_DIR "${ADK_DIR}/PAL/Linux")

# collect adk sources
set(ADK_SRCS    "${ADK_DIR}/PAL/HAPAssert.c"
                "${ADK_DIR}/PAL/HAPBase+Crypto.c"
                "${ADK_DIR}/PAL/HAPBase+Double.c"
                "${ADK_DIR}/PAL/HAPBase+Float.c"
                "${ADK_DIR}/PAL/HAPBase+Int.c"
                "${ADK_DIR}/PAL/HAPBase+MACAddress.c"
                "${ADK_DIR}/PAL/HAPBase+RawBuffer.c"
                "${ADK_DIR}/PAL/HAPBase+Sha1Checksum.c"
                "${ADK_DIR}/PAL/HAPBase+String.c"
                "${ADK_DIR}/PAL/HAPBase+UTF8.c"
                "${ADK_DIR}/PAL/HAPLog.c"
                "${ADK_DIR}/PAL/HAPPlatformSystemInit.c"
                "${ADK_DIR}/HAP/HAPAccessory+Info.c"
                "${ADK_DIR}/HAP/HAPAccessoryServer+Reset.c"
                "${ADK_DIR}/HAP/HAPAccessoryServer.c"
                "${ADK_DIR}/HAP/HAPAccessorySetup.c"
                "${ADK_DIR}/HAP/HAPAccessorySetupInfo.c"
                "${ADK_DIR}/HAP/HAPAccessoryValidation.c"
                "${ADK_DIR}/HAP/HAPBLEAccessoryServer+Advertising.c"
                "${ADK_DIR}/HAP/HAPBLEAccessoryServer+Broadcast.c"
                "${ADK_DIR}/HAP/HAPBLEAccessoryServer.c"
                "${ADK_DIR}/HAP/HAPBLECharacteristic+Broadcast.c"
                "${ADK_DIR}/HAP/HAPBLECharacteristic+Configuration.c"
                "${ADK_DIR}/HAP/HAPBLECharacteristic+Signature.c"
                "${ADK_DIR}/HAP/HAPBLECharacteristic.c"
                "${ADK_DIR}/HAP/HAPBLECharacteristicParseAndWriteValue.c"
                "${ADK_DIR}/HAP/HAPBLECharacteristicReadAndSerializeValue.c"
                "${ADK_DIR}/HAP/HAPBLEPDU+TLV.c"
                "${ADK_DIR}/HAP/HAPBLEPDU.c"
                "${ADK_DIR}/HAP/HAPBLEPeripheralManager.c"
                "${ADK_DIR}/HAP/HAPBLEProcedure.c"
                "${ADK_DIR}/HAP/HAPBLEProtocol+Configuration.c"
                "${ADK_DIR}/HAP/HAPBLEService+Signature.c"
                "${ADK_DIR}/HAP/HAPBLESession.c"
                "${ADK_DIR}/HAP/HAPBLETransaction.c"
                "${ADK_DIR}/HAP/HAPBitSet.c"
                "${ADK_DIR}/HAP/HAPCharacteristic.c"
                "${ADK_DIR}/HAP/HAPCharacteristicTypes.c"
                "${ADK_DIR}/HAP/HAPDeviceID.c"
                "${ADK_DIR}/HAP/HAPIP+ByteBuffer.c"
                "${ADK_DIR}/HAP/HAPIPAccessory.c"
                "${ADK_DIR}/HAP/HAPIPAccessoryProtocol.c"
                "${ADK_DIR}/HAP/HAPIPAccessoryServer.c"
                "${ADK_DIR}/HAP/HAPIPCharacteristic.c"
                "${ADK_DIR}/HAP/HAPIPSecurityProtocol.c"
                "${ADK_DIR}/HAP/HAPIPServiceDiscovery.c"
                "${ADK_DIR}/HAP/HAPJSONUtils.c"
                "${ADK_DIR}/HAP/HAPLegacyImport.c"
                "${ADK_DIR}/HAP/HAPMACAddress.c"
                "${ADK_DIR}/HAP/HAPMFiHWAuth.c"
                "${ADK_DIR}/HAP/HAPMFiTokenAuth.c"
                "${ADK_DIR}/HAP/HAPPDU.c"
                "${ADK_DIR}/HAP/HAPPairing.c"
                "${ADK_DIR}/HAP/HAPPairingBLESessionCache.c"
                "${ADK_DIR}/HAP/HAPPairingPairSetup.c"
                "${ADK_DIR}/HAP/HAPPairingPairVerify.c"
                "${ADK_DIR}/HAP/HAPPairingPairings.c"
                "${ADK_DIR}/HAP/HAPRequestHandlers+AccessoryInformation.c"
                "${ADK_DIR}/HAP/HAPRequestHandlers+HAPProtocolInformation.c"
                "${ADK_DIR}/HAP/HAPRequestHandlers+Pairing.c"
                "${ADK_DIR}/HAP/HAPRequestHandlers.c"
                "${ADK_DIR}/HAP/HAPServiceTypes.c"
                "${ADK_DIR}/HAP/HAPSession.c"
                "${ADK_DIR}/HAP/HAPStringBuilder.c"
                "${ADK_DIR}/HAP/HAPTLV.c"
                "${ADK_DIR}/HAP/HAPTLVMemory.c"
                "${ADK_DIR}/HAP/HAPTLVReader.c"
                "${ADK_DIR}/HAP/HAPTLVWriter.c"
                "${ADK_DIR}/HAP/HAPUUID.c"
                "${ADK_DIR}/HAP/HAPVersion.c"
                "${ADK_DIR}/External/JSON/util_json_reader.c"
                "${ADK_DIR}/External/HTTP/util_http_reader.c"
                "${ADK_DIR}/External/Base64/util_base64.c")

set(ADK_PAL_LINUX   "${ADK_PAL_LINUX_DIR}/HAPPlatformAbort.c"
                    "${ADK_PAL_LINUX_DIR}/HAPPlatformBLEPeripheralManager.c"
                    "${ADK_PAL_LINUX_DIR}/HAPPlatformAccessorySetup.c"
                    "${ADK_PAL_LINUX_DIR}/HAPPlatformKeyValueStore.c"
                    "${ADK_PAL_LINUX_DIR}/HAPPlatformMFiTokenAuth.c"
                    "${ADK_PAL_LINUX_DIR}/HAPPlatformSystemCommand.c"
                    "${ADK_PAL_LINUX_DIR}/HAPPlatformAccessorySetupDisplay.c"
                    "${ADK_PAL_LINUX_DIR}/HAPPlatform.c"
                    "${ADK_PAL_LINUX_DIR}/HAPPlatformClock.c"
                    "${ADK_PAL_LINUX_DIR}/HAPPlatformRandomNumber.c"
                    "${ADK_PAL_LINUX_DIR}/HAPPlatformTCPStreamManager.c"
                    "${ADK_PAL_LINUX_DIR}/HAPPlatformLog.c"
                    "${ADK_PAL_LINUX_DIR}/HAPPlatformRunLoop.c"
                    "${ADK_PAL_LINUX_DIR}/HAPPlatformAccessorySetupNFC.c"
                    "${ADK_PAL_LINUX_DIR}/HAPPlatformFileManager.c"
                    "${ADK_PAL_LINUX_DIR}/HAPPlatformMFiHWAuth.c"
                    "${ADK_PAL_LINUX_DIR}/HAPPlatformServiceDiscovery.c")

set(ADK_PAL_MBEDTLS_SRCS "${ADK_DIR}/PAL/Crypto/MbedTLS/HAPMbedTLS.c")
set(ADK_PAL_OPENSSL_SRCS "${ADK_DIR}/PAL/Crypto/OpenSSL/HAPOpenSSL.c")
