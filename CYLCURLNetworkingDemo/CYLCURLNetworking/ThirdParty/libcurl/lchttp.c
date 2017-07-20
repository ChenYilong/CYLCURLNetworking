//
//  lchttp.c
//  ALFNetworking
//
//  Created by Elon Chan on 9/16/15.
//  Copyright (c) 2017 Elon Chan Inc. All rights reserved.
//

#include <stdlib.h>
#include <string.h>
#include "lchttp.h"

lchttp_error_t *lchttp_error_init() {
    lchttp_error_t *error = malloc(sizeof(lchttp_error_t));

    if (error) {
        error->code = 0;
        error->message = NULL;
    }

    return error;
}

lchttp_response_t *lchttp_response_init() {
    lchttp_response_t *response = malloc(sizeof(lchttp_response_t));

    if (response) {
        response->code = 0;
        response->header = NULL;
        response->text = NULL;
    }

    return response;
}

void lchttp_response_destroy(lchttp_response_t *response) {
    if (response) {
        if (response->text) {
            free(response->text);
        }
        if (response->header) {
            free(response->header);
        }
        free(response);
    }
}

void lchttp_error_destroy(lchttp_error_t *error) {
    if (error) {
        if (error->message) {
            free(error->message);
        }
        free(error);
    }
}

size_t lchttp_header_callback(char *data, size_t size, size_t nitems, void *userp) {
    size_t realsize = nitems * size;

    if (!realsize) return 0;

    lchttp_response_t *response = (lchttp_response_t *)userp;

    size_t old_size = response->header ? strlen(response->header) : 0;
    size_t new_size = old_size + realsize;

    response->header = realloc(response->header, new_size + 1);

    if (response->header == NULL) {
        fprintf(stderr, "[LCHTTP]: Not enough memory.\n");
        return 0;
    }

    memcpy(&(response->header[old_size]), data, realsize);

    response->header[new_size] = 0;

    return realsize;
}

static size_t lchttp_response_callback(void *data, size_t size, size_t nmemb, void *userp) {
    size_t realsize = size * nmemb;

    if (!realsize) return 0;

    lchttp_response_t *response = (lchttp_response_t *)userp;

    size_t old_size = response->text ? strlen(response->text) : 0;
    size_t new_size = old_size + realsize;

    response->text = realloc(response->text, new_size + 1);

    if (response->text == NULL) {
        fprintf(stderr, "[LCHTTP]: Not enough memory.\n");
        return 0;
    }

    memcpy(&(response->text[old_size]), data, realsize);

    response->text[new_size] = 0;

    return realsize;
}

int lchttp_debug_callback(CURL *curl, curl_infotype type, char *data, size_t size, void *userp) {
    if (type == CURLINFO_TEXT) {
        char *url = NULL;
        curl_easy_getinfo(curl, CURLINFO_EFFECTIVE_URL, &url);
        fprintf(stdout, "[LCHTTP DEBUG]: %s, %s", url, data);
    }

    return 0;
}

static inline
char *lchttp_copy_string(const char *src) {
    char *dst = NULL;

    if (src) {
        size_t size = strlen(src);
        dst = malloc(size + 1);

        if (dst) {
            memcpy(dst, src, size);
            dst[size] = 0;
        }
    }

    return dst;
}

CURLcode lchttp_perform(CURL *curl, lchttp_response_t *response, lchttp_error_t *error) {
    curl_easy_setopt(curl, CURLOPT_HEADERDATA, response);
    curl_easy_setopt(curl, CURLOPT_HEADERFUNCTION, lchttp_header_callback);

    curl_easy_setopt(curl, CURLOPT_WRITEDATA, response);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, lchttp_response_callback);

    curl_easy_setopt(curl, CURLOPT_DEBUGDATA, error);
    curl_easy_setopt(curl, CURLOPT_DEBUGFUNCTION, lchttp_debug_callback);

    CURLcode code = curl_easy_perform(curl);

    if (code == CURLE_OK) {
        curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &response->code);
    } else if (error) {
        error->message = lchttp_copy_string(curl_easy_strerror(code));
        error->code = code;
    }

    return code;
}
