import React, { useState, useEffect } from "react";
import CurrentUser from "./CurrentUser";
import UIButton from "../UI/Button";
import { withRouter } from "react-router-dom";
import ContentWrapper from "../UI/ContentWrapper";

const redirectToLogin = event => {
  location.pathname = `/auth/openam`;
};

const RequireSignIn = props => {
  return (
    <CurrentUser>
      {currentUser => {
        if (!currentUser) {
          return (
            <>
              <div className="w-full container mx-auto px-6">
                <div className="lg:flex -mx-6">
                  <div
                    id="sidebar"
                    className="hidden fixed inset-0 pt-16 h-full bg-white z-90 w-full border-b -mb-16 lg:-mb-0 lg:static lg:h-auto lg:overflow-y-visible lg:border-b-0 lg:pt-0 lg:w-1/4 lg:block lg:border-0 xl:w-1/5"
                  >
                    <ContentWrapper>
                      <UIButton type="submit" onClick={redirectToLogin}>
                        Login
                      </UIButton>
                    </ContentWrapper>
                  </div>
                </div>
              </div>
            </>
          );
        }
        return props.children;
      }}
    </CurrentUser>
  );
};

export default withRouter(RequireSignIn);
