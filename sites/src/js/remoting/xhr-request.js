import Deferred        from "../utils/deferred";
import axios           from "axios"
import Msgpack         from "msgpack"
import HTTPHeaderField from "./http-header-field";
import Error           from "../model/error";

export default class XhrRequest {

    constructor(manager, url, method, body, params ) {
        this.url      = url;
        this.body     = body;
        this.manager  = manager;
        this.method   = method;
        this.params   = params;
        this.deferred = new Deferred();
    }

    result() {
        return this.deferred;
    }

    resendable() {
        return this.method === "GET";
    }

    send() {
        const config = this.buildConfig();
        this.manager.startLoading();
        this.sendRequest(config).then(
            this.onSuccess.bind(this),
            this.onFail.bind(this));
    }

    onSuccess( response ) {
        if (this.canceled) return;
        this.manager.endLoading();
        this.manager.handleResponse(this, response);
    }

    onFail( response ) {
        if (this.canceled) return;
        this.manager.endLoading();
        this.manager.handleError(this, this.convertError(response));
    }

    addAuthorizationHeader(headers) {
      if (!this.manager.sessionManager.isLoggedIn()) return;
      headers[HTTPHeaderField.AUTHORIZATION] =
          "X-JIJI-AUTHENTICATE " + this.manager.sessionManager.getTicket();
    }

    buildConfig() {
        const base = {
            url: this.url,
            method: this.method,
            params: this.params,
            timeout: 1000*60*3,
            transformRequest:  [Msgpack.pack],
            transformResponse: [Msgpack.unpack],
            data: this.body,
            responseType: "arrayBuffer",
            headers: {
              "Content-Type": "application/x-msgpack"
            }
        };
        this.addAuthorizationHeader(base.headers);
        return base;
    }

    cancel() {
        this.canceled = true;
        this.manager.handleError(this, { code: Error.Code.CANCELED });
    }

    sendRequest(setting) {
        return axios(setting);
    }

    isAuthRequest(){
        return (
             this.url.match(/\/api\/authenticator$/)
          && this.method === "POST"
        );
    }

    convertError(response) {
        return {
          response : response,
          code:      this.convertErrorCode(response)
        };
    }

    convertErrorCode(response) {
        switch ( response.status ) {
            case 400 :
                return Error.Code.SERVER_BUSY;
            case 401 :
                return Error.Code.UNAUTHORIZED;
            case 403 :
                return Error.Code.OPERATION_NOT_ALLOWD;
            case 404 :
                return Error.Code.NOT_FOUND;
            case 406 :
                return Error.Code.INVALID_VALUE;
            default:
                return Error.Code.SERVER_BUSY;
        }
    }
}
