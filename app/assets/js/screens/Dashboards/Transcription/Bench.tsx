import React, { useState } from "react";
import { useHistory } from "react-router-dom";
import { useMutation, useQuery } from "@apollo/client";
import Layout from "@js/screens/Layout";
import Crumbs from "@js/components/Dashboards/Transcription/Crumbs";
import UIModalDelete from "@js/components/UI/Modal/Delete";
import FileSetPicker from "@js/components/Dashboards/Transcription/FileSetPicker";
import ModelPicker from "@js/components/Dashboards/Transcription/ModelPicker";
import RunBar from "@js/components/Dashboards/Transcription/RunBar";
import RunsTable from "@js/components/Dashboards/Transcription/RunsTable";
import VariantList from "@js/components/Dashboards/Transcription/VariantList";
import {
  runTitle,
  useStored,
} from "@js/components/Dashboards/Transcription/hooks";
import { runSize } from "@js/components/Dashboards/Transcription/limits";
import {
  DEFAULT_SETTINGS,
  SETTINGS_KEY,
  type Settings,
} from "@js/components/Dashboards/Transcription/settings";
import {
  DELETE_TRANSCRIPTION_BENCH_RUN,
  GET_TRANSCRIPTION_BENCH_RUNS,
  START_TRANSCRIPTION_BENCH_RUN,
} from "@js/components/Dashboards/Transcription/transcription.gql";
import type { RunSummary } from "@js/components/Dashboards/Transcription/types";

const RUNS = { limit: 50, offset: 0 };

export default function TranscriptionBenchScreen() {
  const history = useHistory();
  const [settings, setSettings] = useStored<Settings>(
    SETTINGS_KEY,
    DEFAULT_SETTINGS,
  );
  const patch = (next: Partial<Settings>) =>
    setSettings((previous) => ({ ...previous, ...next }));
  const [runToDelete, setRunToDelete] = useState<RunSummary | null>(null);
  const [deleteError, setDeleteError] = useState<string | null>(null);

  const {
    data,
    loading,
    error: runsError,
    startPolling,
    stopPolling,
  } = useQuery(GET_TRANSCRIPTION_BENCH_RUNS, {
    variables: RUNS,
    fetchPolicy: "cache-and-network",
  });
  const runs: RunSummary[] = data?.transcriptionBenchRuns ?? [];
  // Only a run still on its way is worth asking about again.
  const active = runs.some((run) => run.active > 0);
  React.useEffect(() => {
    if (active) startPolling(5000);
    else stopPolling();
    return stopPolling;
  }, [active, startPolling, stopPolling]);

  const refetchQueries = [
    { query: GET_TRANSCRIPTION_BENCH_RUNS, variables: RUNS },
  ];
  const [startRun] = useMutation(START_TRANSCRIPTION_BENCH_RUN, {
    refetchQueries,
  });
  const [deleteRun] = useMutation(DELETE_TRANSCRIPTION_BENCH_RUN, {
    refetchQueries,
  });

  const variants = settings.variants ?? [];
  const chosenVariants = variants.filter((variant) =>
    settings.selected.includes(variant.id),
  );
  const size = runSize(
    settings.images.length,
    settings.models.length,
    chosenVariants.length,
  );

  const start = async (name: string) => {
    const { data: started } = await startRun({
      variables: {
        name: name || null,
        fileSetIds: settings.images.map((image) => image.id),
        models: settings.models,
        variants: JSON.stringify(chosenVariants),
      },
    });
    const id = started?.startTranscriptionBenchRun?.id;
    if (id) history.push(`/dashboards/transcription/runs/${id}`);
  };

  const confirmDelete = async () => {
    const run = runToDelete;
    setRunToDelete(null);
    if (!run) return;
    try {
      await deleteRun({ variables: { id: run.id } });
      setDeleteError(null);
    } catch (failure) {
      setDeleteError((failure as Error).message);
    }
  };

  return (
    <Layout>
      <section className="section" data-testid="transcription-bench-screen">
        <div className="container is-fluid">
          <Crumbs
            items={[
              { label: "Dashboards", isActive: false },
              {
                label: "Transcription Bench",
                route: "/dashboards/transcription",
                isActive: true,
              },
            ]}
          />
          <h1 className="title">Transcription Bench</h1>
          <p className="subtitle is-6">
            Try prompts, structured outputs and Claude models on Meadow's own
            images, through the same IIIF image and Bedrock request the
            transcriber uses. Each result opens in a viewer with its regions
            drawn on the image.
          </p>

          <div className="box">
            <h2 className="title is-5">
              1. Images{" "}
              <span className="has-text-grey has-text-weight-normal is-size-6">
                {settings.images.length} selected
              </span>
            </h2>
            <FileSetPicker
              selected={settings.images}
              onChange={(images) => patch({ images })}
            />
          </div>

          <div className="columns">
            <div className="column is-4">
              <div className="box">
                <h2 className="title is-5">
                  2. Models{" "}
                  <span className="has-text-grey has-text-weight-normal is-size-6">
                    {settings.models.length} selected
                  </span>
                </h2>
                <ModelPicker
                  selected={settings.models}
                  customModels={settings.customModels}
                  onChange={patch}
                />
              </div>
            </div>
            <div className="column">
              <div className="box">
                <h2 className="title is-5">
                  3. Variants{" "}
                  <span className="has-text-grey has-text-weight-normal is-size-6">
                    {chosenVariants.length} of {variants.length}
                  </span>
                </h2>
                <VariantList
                  variants={variants}
                  selected={settings.selected}
                  onChange={patch}
                />
              </div>
            </div>
          </div>

          <div className="box">
            <h2 className="title is-5">4. Run</h2>
            <RunBar size={size} onRun={start} />
          </div>

          <h2 className="title is-4 mt-6">Previous runs</h2>
          {loading && !data && (
            <progress className="progress is-small is-primary" />
          )}
          {(runsError || deleteError) && (
            <p className="notification is-danger is-light">
              {runsError?.message || deleteError}
            </p>
          )}
          {(data || !loading) && !runsError && (
            <RunsTable runs={runs} onDelete={setRunToDelete} />
          )}
        </div>
      </section>

      <UIModalDelete
        isOpen={!!runToDelete}
        handleClose={() => setRunToDelete(null)}
        handleConfirm={confirmDelete}
        thingToDeleteLabel={runToDelete ? runTitle(runToDelete) : "this run"}
      />
    </Layout>
  );
}
