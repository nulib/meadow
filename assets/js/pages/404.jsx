import React, { useEffect, useState } from "react";
import Main from "../components/Main";

const NotFoundPage = () => {
  return (
    <Main>
      <h1>404</h1>
      <section className="content-block">
        <p>Page / route not found</p>
      </section>
    </Main>
  );
};

export default NotFoundPage;
