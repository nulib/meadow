import { useSubscription } from "@apollo/client";
import { WORK_FILE_SET_ANNOTATION } from "@js/components/Work/Tabs/Structure/Transcription/transcription.gql";

export function useWorkFileSetAnnotation(workId) {
  try {
    const { data, loading, error } = useSubscription(WORK_FILE_SET_ANNOTATION, {
      variables: { workId },
      shouldResubscribe: true,
      fetchPolicy: "no-cache",
    });

    return { data, loading, error };
  } catch (error) {
    return { data: null, loading: false, error };
  }
}
