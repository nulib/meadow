import React, { useCallback, useEffect, useState } from "react";
import { useHistory, useParams } from "react-router-dom";
import { useMutation, useQuery } from "@apollo/client";
import Layout from "@js/screens/Layout";
import Crumbs from "@js/components/Dashboards/Transcription/Crumbs";
import UIModalDelete from "@js/components/UI/Modal/Delete";
import { GET_DC_API_TOKEN } from "@js/components/Work/work.gql";
import RunResults from "@js/components/Dashboards/Transcription/RunResults";
import {
  iiifUrl,
  readStored,
  runTitle,
  useStored,
  writeStored,
} from "@js/components/Dashboards/Transcription/hooks";
import {
  DEFAULT_SETTINGS,
  SETTINGS_KEY,
  type Settings,
} from "@js/components/Dashboards/Transcription/settings";
import {
  DELETE_TRANSCRIPTION_BENCH_RUN,
  GET_TRANSCRIPTION_BENCH_RUN,
  CANCEL_TRANSCRIPTION_BENCH_RESULT,
  CANCEL_TRANSCRIPTION_BENCH_RUN,
  RETRY_TRANSCRIPTION_BENCH_RESULT,
} from "@js/components/Dashboards/Transcription/transcription.gql";
import type { Run } from "@js/components/Dashboards/Transcription/types";

const BENCH = "/dashboards/transcription";

export default function TranscriptionBenchRunScreen() {
  const { id } = useParams<{ id: string }>();
  const history = useHistory();
  const [settings, setSettings] = useStored<Settings>(
    SETTINGS_KEY,
    DEFAULT_SETTINGS,
  );
  const [confirming, setConfirming] = useState(false);
  const [failure, setFailure] = useState<string | null>(null);

  const { data, loading, error, startPolling, stopPolling, refetch } = useQuery(
    GET_TRANSCRIPTION_BENCH_RUN,
    { variables: { id }, fetchPolicy: "cache-and-network" },
  );
  const run: Run | undefined = data?.transcriptionBenchRun ?? undefined;
  const active = (run?.active ?? 0) > 0;
  useEffect(() => {
    if (active) startPolling(2000);
    else stopPolling();
    return stopPolling;
  }, [active, startPolling, stopPolling]);

  // The IIIF server wants this token for images that are not public. It expires, so
  // it is asked for again every few minutes while the page is open.
  const { data: tokenData } = useQuery(GET_DC_API_TOKEN, {
    pollInterval: 4 * 60 * 1000,
  });
  const token: string | undefined = tokenData?.dcApiToken?.token;

  const [retryResult] = useMutation(RETRY_TRANSCRIPTION_BENCH_RESULT);
  const [deleteRun] = useMutation(DELETE_TRANSCRIPTION_BENCH_RUN);

  const retry = useCallback(
    async (resultId: string) => {
      try {
        await retryResult({ variables: { id: resultId } });
        setFailure(null);
        await refetch();
      } catch (problem) {
        setFailure((problem as Error).message);
      }
    },
    [retryResult, refetch],
  );

  const [cancelResult] = useMutation(CANCEL_TRANSCRIPTION_BENCH_RESULT);
  const [cancelRun] = useMutation(CANCEL_TRANSCRIPTION_BENCH_RUN);
  // Cancel one result (its id) or, with no id, everything still under way in the run.
  const cancel = useCallback(
    async (resultId?: string) => {
      try {
        if (resultId) await cancelResult({ variables: { id: resultId } });
        else await cancelRun({ variables: { id } });
        setFailure(null);
      } catch (problem) {
        setFailure((problem as Error).message);
      }
      await refetch();
    },
    [cancelResult, cancelRun, id, refetch],
  );
  const cancelWholeRun = useCallback(() => cancel(), [cancel]);

  const loadSetup = () => {
    if (!run) return;
    const stored = readStored<Settings>(SETTINGS_KEY, DEFAULT_SETTINGS);
    const runVariants = run.variants ?? [];
    const kept = (stored.variants ?? []).filter(
      (variant) => !runVariants.some((each) => each.id === variant.id),
    );
    const thumbnails = new Map(
      (run.results ?? []).map((result) => [
        result.fileSetId,
        iiifUrl(result.imageUrl, "square/300,300/0/default.jpg"),
      ]),
    );
    writeStored<Settings>(SETTINGS_KEY, {
      ...stored,
      variants: [...runVariants, ...kept],
      selected: runVariants.map((variant) => variant.id),
      models: run.models ?? [],
      customModels: [
        ...new Set([...(stored.customModels ?? []), ...(run.models ?? [])]),
      ],
      images: (run.images ?? []).map((image) => ({
        id: image.fileSetId,
        label: image.label || image.fileSetId,
        thumbnail: thumbnails.get(image.fileSetId) ?? null,
      })),
    });
    history.push(BENCH);
  };

  const confirmDelete = async () => {
    setConfirming(false);
    try {
      await deleteRun({ variables: { id } });
      history.push(BENCH);
    } catch (problem) {
      setFailure((problem as Error).message);
    }
  };

  return (
    <Layout>
      <section className="section" data-testid="transcription-bench-run-screen">
        <div className="container is-fluid">
          <Crumbs
            items={[
              { label: "Dashboards", isActive: false },
              { label: "Transcription Bench", route: BENCH, isActive: false },
              {
                label: run ? runTitle(run) : "Run",
                route: `${BENCH}/runs/${id}`,
                isActive: true,
              },
            ]}
          />
          {loading && !run && (
            <progress className="progress is-small is-primary" />
          )}
          {(error || failure) && (
            <p className="notification is-danger is-light">
              {failure || error?.message}
            </p>
          )}
          {!loading && !error && !run && (
            <p className="notification is-danger is-light">Run not found.</p>
          )}
          {run && (
            <RunResults
              run={run}
              columns={settings.columns}
              token={token}
              onColumns={(columns) =>
                setSettings((previous) => ({ ...previous, columns }))
              }
              onRetry={retry}
              onCancel={cancel}
              onCancelRun={cancelWholeRun}
              onUseSetup={loadSetup}
              onDelete={() => setConfirming(true)}
            />
          )}
        </div>
      </section>

      <UIModalDelete
        isOpen={confirming}
        handleClose={() => setConfirming(false)}
        handleConfirm={confirmDelete}
        thingToDeleteLabel={run ? runTitle(run) : "this run"}
      />
    </Layout>
  );
}
